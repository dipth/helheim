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
  alias Helheim.Lastfm.Client

  def sync_listens!(account, tracks) do
    parsed_items = tracks |> Enum.map(&parse_item/1) |> Enum.reject(&is_nil/1)

    Multi.new()
    |> Multi.run(:listens, fn repo, _changes -> insert_listens(repo, account, parsed_items) end)
    |> Multi.run(:account, fn repo, _changes -> update_account(repo, account, parsed_items) end)
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

  # Inserts a listen unless one already exists for the same user and
  # played_at (scrobble timestamps are unique per user), keeping the song's
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

  defp artist_name(track) do
    get_in(track, ["artist", "#text"]) || get_in(track, ["artist", "name"])
  end

  defp song_attrs(track, title, artist) do
    %{
      title: title,
      artist_name: artist,
      album_name: blank_to_nil(get_in(track, ["album", "#text"])),
      cover_image_url: image_url(track["image"], "extralarge"),
      cover_image_url_small: image_url(track["image"], "medium"),
      lastfm_track_url: blank_to_nil(track["url"])
    }
  end

  defp image_url(images, size) do
    (images || [])
    |> Enum.find(fn image -> image["size"] == size end)
    |> case do
      %{"#text" => url} -> blank_to_nil(url) |> reject_placeholder()
      _ -> nil
    end
  end

  defp reject_placeholder(nil), do: nil
  defp reject_placeholder(url) do
    if String.contains?(url, Client.placeholder_image_hash()), do: nil, else: url
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
