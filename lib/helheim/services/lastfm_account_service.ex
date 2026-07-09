defmodule Helheim.LastfmAccountService do
  import Ecto.Query
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.LastfmAccount

  @doc """
  Creates or updates the Last.fm connection for the given user from a
  verified auth session. Reconnecting clears a broken state and keeps the
  existing polling cursor so the gap is backfilled (up to one page); a first
  connect starts tracking from now instead of importing old history.
  """
  def connect!(user, %{username: username, session_key: session_key}) do
    existing = Repo.get_by(LastfmAccount, user_id: user.id)

    attrs = %{
      username: username,
      session_key: session_key,
      broken_at: nil,
      played_after_cursor: (existing && existing.played_after_cursor) || DateTime.to_unix(DateTime.utc_now())
    }

    (existing || Ecto.build_assoc(user, :lastfm_account))
    |> LastfmAccount.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Disconnects the user from the Last.fm feature. The session key is deleted
  and tracking stops, but already tracked listens are kept.
  """
  def disconnect!(user) do
    case Repo.get_by(LastfmAccount, user_id: user.id) do
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

  defp delete_listens!(listens_query) do
    Multi.new()
    |> Multi.run(:counts_per_song, fn repo, _changes ->
      counts = repo.all(from l in subquery(listens_query), group_by: l.song_id, select: {l.song_id, count(l.id)})
      {:ok, counts}
    end)
    |> Multi.delete_all(:delete_listens, listens_query)
    |> Multi.run(:dec_listens_counts, fn repo, %{counts_per_song: counts} ->
      Enum.each(counts, fn {song_id, count} ->
        repo.update_all((from s in Song, where: s.id == ^song_id), inc: [listens_count: -count])
      end)
      {:ok, nil}
    end)
    |> Repo.transaction()
  end
end
