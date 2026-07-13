defmodule Helheim.Music.SongEnrichmentWorker do
  @moduledoc """
  Enriches a song with metadata beyond what the scrobble feed provides:
  MusicBrainz ids, duration, tags (the first doubling as the genre), a
  higher resolution cover, the release year (via MusicBrainz) and a link
  to its artist record.

  Runs on the concurrency-1 :enrichment queue and sleeps after each
  MusicBrainz call, which keeps us within their 1 request/second policy on
  a single-node deployment. Partial results are fine: enriched_at is
  stamped even when some sources had nothing, and a re-run can be forced
  with the "force" arg.
  """

  use Oban.Worker,
    queue: :enrichment,
    max_attempts: 5,
    unique: [period: 3600, keys: [:song_id]]

  import Ecto.Query
  alias Helheim.Repo
  alias Helheim.Artist
  alias Helheim.Song
  alias Helheim.SongTag
  alias Helheim.Tag
  alias Helheim.Lastfm
  alias Helheim.Musicbrainz
  alias Helheim.Music.ArtistEnrichmentWorker

  @max_tags 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"song_id" => song_id} = args}) do
    song = Repo.get(Song, song_id)

    cond do
      is_nil(song) -> :ok
      song.enriched_at && args["force"] != true -> :ok
      true -> enrich(song, args["force"] == true)
    end
  end

  defp enrich(song, force) do
    with {:ok, song} <- apply_track_info(song),
         {:ok, song} <- apply_release_year(song, force),
         {:ok, song} <- link_artist(song) do
      {:ok, _} =
        song
        |> Song.changeset(%{enriched_at: DateTime.utc_now()})
        |> Repo.update()

      :ok
    else
      {:error, :rate_limited} -> {:snooze, 60}
      {:error, reason} -> {:error, reason}
    end
  end

  # Fetches track.getInfo and merges what we do not already know; existing
  # values are never clobbered.
  defp apply_track_info(song) do
    case Lastfm.Client.track_info(song.artist_name, song.title) do
      {:ok, info} ->
        attrs = %{
          mbid: song.mbid || info.mbid,
          artist_mbid: song.artist_mbid || info.artist_mbid,
          album_mbid: song.album_mbid || info.album_mbid,
          album_name: song.album_name || info.album_name,
          duration_seconds: song.duration_seconds || info.duration_seconds,
          cover_image_url: song.cover_image_url || info.image_extralarge,
          lastfm_track_url: song.lastfm_track_url || info.url
        }

        {:ok, song} = song |> Song.changeset(attrs) |> Repo.update()
        replace_tags(song, with_artist_tags_fallback(info.tags, song))
        {:ok, upgrade_cover(song)}

      {:error, :not_found} ->
        replace_tags(song, with_artist_tags_fallback([], song))
        {:ok, song}

      error ->
        error
    end
  end

  # Track-level tags are sparse on Last.fm outside the mainstream; the
  # artist's tags are a much better genre signal than nothing.
  defp with_artist_tags_fallback([], song) do
    case Lastfm.Client.artist_info(song.artist_name) do
      {:ok, %{tags: tags}} -> tags
      _ -> []
    end
  end
  defp with_artist_tags_fallback(tags, _song), do: tags

  # The Last.fm API caps artwork at 300px, but its CDN serves a 500px
  # rendition of the same image under a rewritten path - the same trick
  # last.fm's own album pages use.
  defp upgrade_cover(%Song{cover_image_url: nil} = song), do: song
  defp upgrade_cover(%Song{} = song) do
    large = String.replace(song.cover_image_url, "/300x300/", "/500x500/")

    if large != song.cover_image_url do
      {:ok, song} = song |> Song.changeset(%{cover_image_url_large: large}) |> Repo.update()
      song
    else
      song
    end
  end

  defp replace_tags(song, tag_names) do
    tags =
      tag_names
      |> Enum.map(&String.trim/1)
      |> Enum.reject(fn name -> name == "" or String.length(name) > 40 end)
      |> Enum.uniq_by(&String.downcase/1)
      |> Enum.take(@max_tags)

    Repo.delete_all(from st in SongTag, where: st.song_id == ^song.id)

    tags
    |> Enum.with_index(1)
    |> Enum.each(fn {name, position} ->
      tag = Tag.get_or_create_by_name!(name)

      %SongTag{song_id: song.id, tag_id: tag.id}
      |> SongTag.changeset(%{position: position})
      |> Repo.insert!(on_conflict: :nothing, conflict_target: [:song_id, :tag_id])
    end)
  end

  # Release year lookup cascade: the recording by track mbid, then the
  # release group via the album mbid (Last.fm album mbids are MusicBrainz
  # release ids), then a recording search by artist + title. Stale Last.fm
  # mbids 404 on MusicBrainz, so every step falls through on :not_found.
  # A force run re-derives the year so bad data can be corrected.
  defp apply_release_year(%Song{release_year: year} = song, false) when is_integer(year), do: {:ok, song}
  defp apply_release_year(song, _force) do
    case release_year_cascade(song) do
      {:ok, nil} ->
        {:ok, song}
      {:ok, year} ->
        {:ok, _} = song |> Song.changeset(%{release_year: year}) |> Repo.update()
        {:ok, %{song | release_year: year}}
      error ->
        error
    end
  end

  defp release_year_cascade(song) do
    with {:ok, nil} <- year_from_recording(song.mbid),
         {:ok, nil} <- year_from_release(song.album_mbid) do
      year_from_search(song.artist_name, song.title)
    end
  end

  defp year_from_recording(nil), do: {:ok, nil}
  defp year_from_recording(mbid) do
    Musicbrainz.Client.recording(mbid)
    |> musicbrainz_pause()
    |> case do
      {:ok, %{"first-release-date" => date}} -> {:ok, parse_year(date)}
      {:ok, _} -> {:ok, nil}
      {:error, :not_found} -> {:ok, nil}
      error -> error
    end
  end

  defp year_from_release(nil), do: {:ok, nil}
  defp year_from_release(mbid) do
    Musicbrainz.Client.release(mbid)
    |> musicbrainz_pause()
    |> case do
      {:ok, %{"release-group" => %{"first-release-date" => date}}} -> {:ok, parse_year(date)}
      {:ok, _} -> {:ok, nil}
      {:error, :not_found} -> {:ok, nil}
      error -> error
    end
  end

  # Search results include remasters and compilation recordings whose
  # first-release-date is years after the original, so take the earliest
  # year across the hits rather than trusting the top-scored one.
  defp year_from_search(artist, title) do
    Musicbrainz.Client.search_recording(artist, title)
    |> musicbrainz_pause()
    |> case do
      {:ok, recordings} when is_list(recordings) ->
        year =
          recordings
          |> Enum.map(fn recording -> parse_year(recording["first-release-date"]) end)
          |> Enum.reject(&is_nil/1)
          |> Enum.min(fn -> nil end)

        {:ok, year}
      {:ok, _} ->
        {:ok, nil}
      {:error, :not_found} ->
        {:ok, nil}
      error ->
        error
    end
  end

  defp parse_year(date) when is_binary(date) do
    case Integer.parse(String.slice(date, 0, 4)) do
      {year, _} when year > 1000 -> year
      _ -> nil
    end
  end
  defp parse_year(_), do: nil

  defp musicbrainz_pause(result) do
    Process.sleep(Helheim.Musicbrainz.pause_ms())
    result
  end

  defp link_artist(song) do
    artist = Artist.get_or_create_by_name!(song.artist_name)

    if song.artist_mbid && is_nil(artist.mbid) do
      {:ok, _} = artist |> Artist.changeset(%{mbid: song.artist_mbid}) |> Repo.update()
    end

    if is_nil(song.artist_id) do
      {:ok, _} = song |> Ecto.Changeset.change(artist_id: artist.id) |> Repo.update()
    end

    if is_nil(artist.enriched_at) do
      %{artist_id: artist.id}
      |> ArtistEnrichmentWorker.new()
      |> Oban.insert()
    end

    {:ok, Repo.get(Song, song.id)}
  end
end
