defmodule Helheim.LastfmAccountService do
  import Ecto.Query
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.LastfmAccount

  @doc """
  Creates or updates the Last.fm connection for the given user from a
  verified auth session. Reconnecting the same Last.fm account clears a
  broken state and keeps the existing polling cursor so the gap is
  backfilled (up to one page); a first connect or a switch to a different
  Last.fm account starts tracking from now instead of importing history
  that belongs to another timeline.
  """
  def connect!(user, %{username: username, session_key: session_key}) do
    existing = LastfmAccount.get_for_user(user)

    attrs = %{
      username: username,
      session_key: session_key,
      broken_at: nil,
      played_after_cursor: existing_cursor(existing, username) || DateTime.to_unix(DateTime.utc_now())
    }

    (existing || Ecto.build_assoc(user, :lastfm_account))
    |> LastfmAccount.changeset(attrs)
    |> Repo.insert_or_update()
  end

  defp existing_cursor(nil, _username), do: nil
  defp existing_cursor(existing, username) do
    if String.downcase(existing.username) == String.downcase(username) do
      existing.played_after_cursor
    else
      nil
    end
  end

  @doc """
  Disconnects the user from the Last.fm feature. The session key is deleted
  and tracking stops, but already tracked listens are kept.
  """
  def disconnect!(user) do
    case LastfmAccount.get_for_user(user) do
      nil -> {:ok, nil}
      account -> Repo.delete(account)
    end
  end

  @doc """
  Deletes the user's entire listening history and keeps the song listen
  counters in sync. Does not touch the Last.fm connection itself.
  """
  def delete_history!(user) do
    delete_listens!(from l in SongListen, where: l.user_id == ^user.id)
  end

  @doc """
  Deletes the user's listens of a single song, removing their name from it.
  """
  def delete_listens_for_song!(user, song) do
    delete_listens!(from l in SongListen, where: l.user_id == ^user.id and l.song_id == ^song.id)
  end

  # The counter decrement runs as a single UPDATE joined against the grouped
  # listens (before they are deleted), so the whole operation is two
  # statements regardless of how large the listening history is.
  defp delete_listens!(listens_query) do
    counts_query =
      from l in subquery(listens_query),
        group_by: l.song_id,
        select: %{song_id: l.song_id, listen_count: count(l.id)}

    dec_query =
      from s in Song,
        join: c in subquery(counts_query), on: c.song_id == s.id,
        update: [set: [listens_count: s.listens_count - c.listen_count]]

    Multi.new()
    |> Multi.update_all(:dec_listens_counts, dec_query, [])
    |> Multi.delete_all(:delete_listens, listens_query)
    |> Repo.transaction()
  end
end
