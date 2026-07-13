defmodule Helheim.Lastfm.SyncService do
  @moduledoc """
  Persists a batch of Last.fm scrobbles for a connected user: upserts songs
  by their case-insensitive artist + title identity (refreshing metadata
  without clobbering it with blanks), inserts listens idempotently and
  advances the account's polling cursor.

  Only a single page of max 200 scrobbles is processed per poll; a user
  scrobbling more than 200 tracks between two polls (e.g. a bulk import)
  will have the overflow skipped, which is acceptable.
  """

  import Ecto.Query
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.LastfmAccount
  alias Helheim.Music.SongEnrichmentWorker

  # The image Last.fm serves when it has no album art.
  @placeholder_image_hash "2a96cbd8b46e442fc41c2b86b821562f"

  # A full page of 200 scrobbles is several hundred queries in one
  # transaction; against a remote database (Neon) that far exceeds the
  # default 15s connection checkout timeout.
  @sync_timeout :timer.minutes(2)

  def sync_listens!(account, tracks) do
    parsed_items = tracks |> Enum.map(&parse_item/1) |> Enum.reject(&is_nil/1)

    Multi.new()
    |> Multi.run(:listens, fn repo, _changes -> insert_listens(repo, account, parsed_items) end)
    |> Multi.run(:account, fn repo, _changes -> update_account(repo, account, parsed_items) end)
    |> Repo.transaction(timeout: @sync_timeout)
    |> case do
      {:ok, %{listens: %{song_ids: song_ids}}} = result ->
        enqueue_enrichment(song_ids)
        result
      other ->
        other
    end
  end

  defp insert_listens(repo, account, parsed_items) do
    {listens, song_ids} =
      Enum.map_reduce(parsed_items, MapSet.new(), fn {song_attrs, played_at}, song_ids ->
        song = upsert_song!(repo, song_attrs)
        {insert_listen!(repo, account.user_id, song, played_at), MapSet.put(song_ids, song.id)}
      end)

    {:ok, %{listens: Enum.reject(listens, &is_nil/1), song_ids: MapSet.to_list(song_ids)}}
  end

  # Songs that have not been enriched yet (typically the ones this batch
  # created) get an enrichment job; job uniqueness dedupes across polls.
  defp enqueue_enrichment([]), do: :ok
  defp enqueue_enrichment(song_ids) do
    Song
    |> Song.unenriched()
    |> where([s], s.id in ^song_ids)
    |> select([s], s.id)
    |> Repo.all()
    |> Enum.each(fn song_id ->
      %{song_id: song_id}
      |> SongEnrichmentWorker.new()
      |> Oban.insert()
    end)
  end

  # Songs are identified by lower(artist_name) + lower(title). On conflict
  # the metadata is refreshed, but only with non-nil values: a later scrobble
  # of the same track often lacks album or artwork data and must not clobber
  # what an earlier scrobble provided.
  defp upsert_song!(repo, song_attrs) do
    on_conflict =
      from s in Song,
        update: [set: [
          title: fragment("EXCLUDED.title"),
          artist_name: fragment("EXCLUDED.artist_name"),
          album_name: fragment("COALESCE(EXCLUDED.album_name, ?)", s.album_name),
          cover_image_url: fragment("COALESCE(EXCLUDED.cover_image_url, ?)", s.cover_image_url),
          cover_image_url_small: fragment("COALESCE(EXCLUDED.cover_image_url_small, ?)", s.cover_image_url_small),
          lastfm_track_url: fragment("COALESCE(EXCLUDED.lastfm_track_url, ?)", s.lastfm_track_url),
          mbid: fragment("COALESCE(EXCLUDED.mbid, ?)", s.mbid),
          artist_mbid: fragment("COALESCE(EXCLUDED.artist_mbid, ?)", s.artist_mbid),
          album_mbid: fragment("COALESCE(EXCLUDED.album_mbid, ?)", s.album_mbid),
          updated_at: fragment("EXCLUDED.updated_at")
        ]]

    %Song{}
    |> Song.changeset(song_attrs)
    |> repo.insert!(
      on_conflict: on_conflict,
      conflict_target: {:unsafe_fragment, "(lower(artist_name), lower(title))"},
      returning: true
    )
  end

  # Inserts a listen unless the same scrobble was already imported by an
  # earlier poll, keeping the song's listens_count in step with genuinely
  # new rows only. The song is part of the identity because bulk imports can
  # stamp two different tracks with the same second.
  defp insert_listen!(repo, user_id, song, played_at) do
    listen =
      %SongListen{user_id: user_id, song_id: song.id, played_at: played_at}
      |> repo.insert!(on_conflict: :nothing, conflict_target: [:user_id, :played_at, :song_id])

    if listen.id do
      repo.update_all((from s in Song, where: s.id == ^song.id), inc: [listens_count: 1])
      listen
    else
      nil
    end
  end

  defp update_account(repo, account, parsed_items) do
    account
    |> LastfmAccount.changeset(%{
      last_polled_at: DateTime.utc_now(),
      played_after_cursor: max_played_at_uts(parsed_items) || account.played_after_cursor
    })
    |> repo.update()
  end

  defp max_played_at_uts([]), do: nil
  defp max_played_at_uts(parsed_items) do
    parsed_items
    |> Enum.map(fn {_song_attrs, played_at} -> DateTime.to_unix(played_at) end)
    |> Enum.max()
  end

  # The currently playing track carries a nowplaying attribute and no date;
  # it is skipped and will be picked up once it has actually been scrobbled.
  # All field access is defensive against shape drift in the API response,
  # so one malformed item is skipped instead of crashing the whole batch.
  defp parse_item(%{"@attr" => %{"nowplaying" => "true"}}), do: nil
  defp parse_item(%{"date" => %{"uts" => uts}} = track) do
    with {uts, ""} <- Integer.parse("#{uts}"),
         title when is_binary(title) and title != "" <- track["name"],
         artist when is_binary(artist) and artist != "" <- artist_name(track) do
      played_at = uts |> DateTime.from_unix!() |> Map.put(:microsecond, {0, 6})
      {song_attrs(track, title, artist), played_at}
    else
      _ -> nil
    end
  end
  defp parse_item(_), do: nil

  defp artist_name(%{"artist" => %{} = artist}), do: artist["#text"] || artist["name"]
  defp artist_name(_), do: nil

  defp album_name(%{"album" => %{"#text" => album}}), do: blank_to_nil(album)
  defp album_name(_), do: nil

  defp song_attrs(track, title, artist) do
    %{
      title: title,
      artist_name: artist,
      album_name: album_name(track),
      cover_image_url: image_url(track["image"], "extralarge"),
      cover_image_url_small: image_url(track["image"], "medium"),
      lastfm_track_url: blank_to_nil(track["url"]),
      mbid: blank_to_nil(track["mbid"]),
      artist_mbid: mbid_of(track["artist"]),
      album_mbid: mbid_of(track["album"])
    }
  end

  defp mbid_of(%{"mbid" => mbid}), do: blank_to_nil(mbid)
  defp mbid_of(_), do: nil

  defp image_url(images, size) when is_list(images) do
    images
    |> Enum.find(fn image -> is_map(image) && image["size"] == size end)
    |> case do
      %{"#text" => url} when is_binary(url) -> blank_to_nil(url) |> reject_placeholder()
      _ -> nil
    end
  end
  defp image_url(_, _), do: nil

  defp reject_placeholder(nil), do: nil
  defp reject_placeholder(url) do
    if String.contains?(url, @placeholder_image_hash), do: nil, else: url
  end

  defp blank_to_nil(value) when is_binary(value) and value != "", do: value
  defp blank_to_nil(_), do: nil
end
