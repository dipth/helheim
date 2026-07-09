defmodule Helheim.SpotifyAccountService do
  import Ecto.Query
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.SpotifyAccount
  alias Helheim.Spotify.Client

  @doc """
  Creates or updates the Spotify connection for the given user from a token
  response. Reconnecting clears a broken state and resets the polling cursor.
  """
  def connect!(user, %{"access_token" => access_token} = token_data) do
    spotify_user_id = case Client.me(access_token) do
      {:ok, %{"id" => id}} -> id
      _ -> nil
    end

    attrs = %{
      spotify_user_id: spotify_user_id,
      access_token: access_token,
      refresh_token: token_data["refresh_token"],
      token_expires_at: expires_at(token_data["expires_in"]),
      scopes: token_data["scope"],
      broken_at: nil,
      played_after_cursor: nil
    }

    (Repo.get_by(SpotifyAccount, user_id: user.id) || Ecto.build_assoc(user, :spotify_account))
    |> SpotifyAccount.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Persists a refreshed token pair. Spotify does not always return a new
  refresh token, in which case the existing one is kept.
  """
  def update_tokens!(account, token_data) do
    attrs = %{
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"] || account.refresh_token,
      token_expires_at: expires_at(token_data["expires_in"])
    }

    account
    |> SpotifyAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Disconnects the user from the Spotify feature. Tokens are deleted and
  tracking stops, but already tracked listens are kept.
  """
  def disconnect!(user) do
    case Repo.get_by(SpotifyAccount, user_id: user.id) do
      nil -> {:ok, nil}
      account -> Repo.delete(account)
    end
  end

  @doc """
  Deletes the user's entire listening history and keeps the song listen
  counters in sync. Does not touch the Spotify connection itself.
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

  defp expires_at(expires_in) when is_integer(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
  defp expires_at(_), do: DateTime.add(DateTime.utc_now(), 3600, :second)
end
