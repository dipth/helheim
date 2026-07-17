defmodule Helheim.Music.SongEnrichmentWorker do
  @moduledoc """
  Enriches a song with metadata beyond what the scrobble feed provides:
  MusicBrainz ids, duration, tags (the first doubling as the genre), a
  higher resolution cover, the release year (via MusicBrainz), a Deezer
  track id (for 30 second previews) and a link to its artist record.

  MusicBrainz calls are paced cluster-wide through Helheim.Musicbrainz.paced/1.
  Partial results are fine: enriched_at is stamped even when some sources
  had nothing, and when the final attempt still errors the song is settled
  (stamped and logged) so it cannot clog the queue forever - the hourly
  sweep or a "force" re-run are the recovery paths.
  """

  use Oban.Worker,
    queue: :enrichment,
    max_attempts: 5,
    unique: [
      period: 3600,
      keys: [:song_id],
      states: [:available, :scheduled, :executing, :retryable, :suspended]
    ]

  import Ecto.Query
  require Logger
  alias Helheim.Cache
  alias Helheim.Repo
  alias Helheim.Artist
  alias Helheim.Song
  alias Helheim.SongTag
  alias Helheim.Tag
  alias Helheim.Lastfm
  alias Helheim.Musicbrainz
  alias Helheim.Deezer
  alias Helheim.Music.ArtistEnrichmentWorker

  @max_tags 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"song_id" => song_id} = args} = job) do
    song = Repo.get(Song, song_id)

    cond do
      is_nil(song) -> :ok
      song.enriched_at && args["force"] != true -> :ok
      true -> song |> enrich(args["force"] == true) |> settle_final_attempt(job, song)
    end
  end

  # A song that still errors on its last attempt is stamped as enriched so
  # future polls/sweeps stop re-enqueueing it; force re-runs can revisit.
  defp settle_final_attempt({:error, reason}, %Oban.Job{attempt: attempt, max_attempts: max}, song) when attempt >= max do
    Logger.error("Song enrichment settled with error for song #{song.id}: #{inspect(reason)}")
    {:ok, _} = song |> Song.changeset(%{enriched_at: DateTime.utc_now()}) |> Repo.update()
    :ok
  end
  defp settle_final_attempt(result, _job, _song), do: result

  defp enrich(song, force) do
    with {:ok, song, tags} <- apply_track_info(song),
         :ok <- apply_tags(song, tags),
         {:ok, deezer_id} <- resolve_deezer_id(song, force),
         {:ok, release_year} <- resolve_release_year(song, force),
         {:ok, artist} <- ensure_artist(song) do
      {:ok, _} =
        song
        |> Song.changeset(%{
          release_year: release_year || song.release_year,
          deezer_id: deezer_id || song.deezer_id,
          enriched_at: DateTime.utc_now()
        })
        |> Ecto.Changeset.put_change(:artist_id, song.artist_id || artist.id)
        |> Repo.update()

      :ok
    else
      {:error, :rate_limited} -> {:snooze, 60}
      {:error, reason} -> {:error, reason}
    end
  end

  # Fetches track.getInfo and merges what we do not already know in a
  # single write; existing values are never clobbered. The 500px cover is
  # derived here too: the Last.fm API caps artwork at 300px, but its CDN
  # serves a 500px rendition under a rewritten path - the same trick
  # last.fm's own album pages use.
  defp apply_track_info(song) do
    case Lastfm.Client.track_info(song.artist_name, song.title) do
      {:ok, info} ->
        cover = song.cover_image_url || info.image_extralarge

        attrs = %{
          mbid: song.mbid || info.mbid,
          artist_mbid: song.artist_mbid || info.artist_mbid,
          album_mbid: song.album_mbid || info.album_mbid,
          album_name: song.album_name || info.album_name,
          duration_seconds: song.duration_seconds || info.duration_seconds,
          cover_image_url: cover,
          cover_image_url_large: upgraded_cover_url(cover),
          lastfm_track_url: song.lastfm_track_url || info.url
        }

        {:ok, song} = song |> Song.changeset(attrs) |> Repo.update()
        {:ok, song, info.tags}

      {:error, :not_found} ->
        {:ok, song, []}

      error ->
        error
    end
  end

  defp upgraded_cover_url(nil), do: nil
  defp upgraded_cover_url(url) do
    case String.replace(url, "/300x300/", "/500x500/") do
      ^url -> nil
      upgraded -> upgraded
    end
  end

  defp apply_tags(song, track_tags) do
    case with_artist_tags_fallback(track_tags, song) do
      {:error, :rate_limited} -> {:error, :rate_limited}
      tags -> replace_tags(song, tags)
    end
  end

  # Track-level tags are sparse on Last.fm outside the mainstream; the
  # artist's tags are a much better genre signal than nothing. The artist
  # lookup is cached so a discography of tagless tracks costs one API call,
  # and rate limits propagate so the job snoozes instead of losing tags.
  defp with_artist_tags_fallback([], song) do
    Cache.fetch(
      {:lastfm_artist_tags, String.downcase(song.artist_name)},
      api_cache_ttl(),
      fn -> Lastfm.Client.artist_info(song.artist_name) end,
      cache_if: &match?({:ok, _}, &1)
    )
    |> case do
      {:ok, %{tags: tags}} -> tags
      {:error, :rate_limited} -> {:error, :rate_limited}
      _ -> []
    end
  end
  defp with_artist_tags_fallback(tags, _song), do: tags

  # An empty result never wipes tags a song already has: stale tags beat
  # data loss from a transient upstream hiccup.
  defp replace_tags(_song, []), do: :ok
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

    :ok
  end

  # Release year lookup cascade: the recording by track mbid, then the
  # release group via the album mbid (Last.fm album mbids are MusicBrainz
  # release ids), then a recording search by artist + title. Stale Last.fm
  # mbids 404 on MusicBrainz, so every step falls through on :not_found.
  # Returns the year without persisting; the caller folds it into the
  # final write.
  defp resolve_release_year(%Song{release_year: year}, false) when is_integer(year), do: {:ok, year}
  defp resolve_release_year(song, _force) do
    with {:ok, nil} <- year_from_recording(song.mbid),
         {:ok, nil} <- year_from_release(song.album_mbid) do
      year_from_search(song.artist_name, song.title)
    end
  end

  defp year_from_recording(nil), do: {:ok, nil}
  defp year_from_recording(mbid) do
    Musicbrainz.paced(fn -> Musicbrainz.Client.recording(mbid) end)
    |> case do
      {:ok, %{"first-release-date" => date}} -> {:ok, parse_year(date)}
      {:ok, _} -> {:ok, nil}
      {:error, :not_found} -> {:ok, nil}
      error -> error
    end
  end

  defp year_from_release(nil), do: {:ok, nil}
  defp year_from_release(mbid) do
    Musicbrainz.paced(fn -> Musicbrainz.Client.release(mbid) end)
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
    Musicbrainz.paced(fn -> Musicbrainz.Client.search_recording(artist, title) end)
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

  # The Deezer id powers the on-demand preview endpoint (preview URLs
  # themselves expire, so only the id is stored). This step runs before
  # the release year cascade on purpose: a Deezer rate limit then snoozes
  # the job before any paced MusicBrainz work is spent (the retry does
  # still repeat the Last.fm lookup - apply_track_info runs every
  # attempt). Other Deezer errors degrade to "no preview" instead of
  # gating the year/artist steps behind an optional field: a song settled
  # during a Deezer hiccup keeps its core metadata, and
  # mix helheim.preview_backfill re-checks any song still missing its
  # deezer_id, so previews are recoverable in bulk.
  defp resolve_deezer_id(%Song{deezer_id: deezer_id}, false) when is_integer(deezer_id), do: {:ok, deezer_id}
  defp resolve_deezer_id(song, _force) do
    case Deezer.Client.search_track(song.artist_name, song.title) do
      {:ok, %{deezer_id: deezer_id}} -> {:ok, deezer_id}
      {:error, :rate_limited} -> {:error, :rate_limited}
      _ -> {:ok, nil}
    end
  end

  defp parse_year(date) when is_binary(date) do
    case Integer.parse(String.slice(date, 0, 4)) do
      {year, _} when year > 1000 -> year
      _ -> nil
    end
  end
  defp parse_year(_), do: nil

  defp ensure_artist(song) do
    artist = Artist.get_or_create_by_name!(song.artist_name)

    if song.artist_mbid && is_nil(artist.mbid) do
      {:ok, _} = artist |> Artist.changeset(%{mbid: song.artist_mbid}) |> Repo.update()
    end

    if is_nil(artist.enriched_at) do
      %{artist_id: artist.id}
      |> ArtistEnrichmentWorker.new()
      |> Oban.insert()
    end

    {:ok, artist}
  end

  defp api_cache_ttl do
    Application.get_env(:helheim, :api_cache_ttl_ms, :timer.hours(24))
  end
end
