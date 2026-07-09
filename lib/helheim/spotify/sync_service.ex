defmodule Helheim.Spotify.SyncService do
  @moduledoc """
  Persists a batch of Spotify "recently played" items for a connected user:
  upserts songs by spotify_track_id (refreshing their metadata), inserts
  listens idempotently and advances the account's polling cursor.
  """

  import Ecto.Query
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.SpotifyAccount

  def sync_listens!(account, items, next_after \\ nil) do
    parsed_items = items |> Enum.map(&parse_item/1) |> Enum.reject(&is_nil/1)

    Multi.new()
    |> Multi.run(:listens, fn repo, _changes -> insert_listens(repo, account, parsed_items) end)
    |> Multi.run(:account, fn repo, _changes -> update_account(repo, account, parsed_items, next_after) end)
    |> Repo.transaction()
  end

  defp insert_listens(repo, account, parsed_items) do
    listens =
      Enum.map(parsed_items, fn {song_attrs, played_at} ->
        song = upsert_song!(repo, song_attrs)
        insert_listen!(repo, account.user_id, song, played_at)
      end)

    {:ok, Enum.reject(listens, &is_nil/1)}
  end

  defp upsert_song!(repo, song_attrs) do
    %Song{}
    |> Song.changeset(song_attrs)
    |> repo.insert!(
      on_conflict: {:replace, Song.metadata_fields() ++ [:updated_at]},
      conflict_target: :spotify_track_id,
      returning: true
    )
  end

  # Inserts a listen unless one already exists for the same user and
  # played_at (Spotify timestamps are unique per user), keeping the song's
  # listens_count in step with genuinely new rows only.
  defp insert_listen!(repo, user_id, song, played_at) do
    listen =
      %SongListen{user_id: user_id, song_id: song.id, played_at: played_at}
      |> repo.insert!(on_conflict: :nothing, conflict_target: [:user_id, :played_at])

    if listen.id do
      repo.update_all((from s in Song, where: s.id == ^song.id), inc: [listens_count: 1])
      listen
    else
      nil
    end
  end

  defp update_account(repo, account, parsed_items, next_after) do
    account
    |> SpotifyAccount.changeset(%{
      last_polled_at: DateTime.utc_now(),
      played_after_cursor: next_after || max_played_at_ms(parsed_items) || account.played_after_cursor
    })
    |> repo.update()
  end

  defp max_played_at_ms([]), do: nil
  defp max_played_at_ms(parsed_items) do
    parsed_items
    |> Enum.map(fn {_song_attrs, played_at} -> DateTime.to_unix(played_at, :millisecond) end)
    |> Enum.max()
  end

  # Non-track items (e.g. podcast episodes) and unparsable timestamps are
  # skipped.
  defp parse_item(%{"track" => %{"id" => track_id} = track, "played_at" => played_at}) when is_binary(track_id) do
    case DateTime.from_iso8601(played_at) do
      {:ok, played_at, _offset} ->
        # Spotify timestamps have millisecond precision, but the played_at
        # column expects microseconds
        {microsecond, _precision} = played_at.microsecond
        {song_attrs(track), %{played_at | microsecond: {microsecond, 6}}}
      _ ->
        nil
    end
  end
  defp parse_item(_), do: nil

  defp song_attrs(track) do
    artist = List.first(track["artists"] || []) || %{}
    album = track["album"] || %{}
    images = album["images"] || []

    %{
      spotify_track_id: track["id"],
      title: track["name"],
      artist_name: artist["name"],
      artist_spotify_id: artist["id"],
      album_name: album["name"],
      album_spotify_id: album["id"],
      cover_image_url: image_url(images, 300),
      cover_image_url_small: image_url(images, 64),
      spotify_track_url: get_in(track, ["external_urls", "spotify"]),
      spotify_artist_url: get_in(artist, ["external_urls", "spotify"]),
      spotify_album_url: get_in(album, ["external_urls", "spotify"]),
      duration_ms: track["duration_ms"],
      preview_url: track["preview_url"]
    }
  end

  defp image_url(images, size) do
    exact = Enum.find(images, fn image -> image["height"] == size end)
    fallback = List.first(images)
    (exact || fallback || %{})["url"]
  end
end
