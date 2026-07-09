defmodule Helheim.Spotify.PollWorker do
  @moduledoc """
  Polls Spotify's recently played endpoint for a single connected account.
  Refreshes expired tokens, marks the connection broken when the refresh
  token is no longer valid and snoozes on rate limits.
  """

  use Oban.Worker,
    queue: :spotify,
    max_attempts: 3,
    unique: [period: 240, keys: [:spotify_account_id]]

  alias Helheim.Repo
  alias Helheim.SpotifyAccount
  alias Helheim.SpotifyAccountService
  alias Helheim.Spotify.Client
  alias Helheim.Spotify.SyncService

  @token_freshness_margin_in_seconds 60

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"spotify_account_id" => spotify_account_id}}) do
    case Repo.get(SpotifyAccount, spotify_account_id) do
      nil -> :ok
      %SpotifyAccount{broken_at: %DateTime{}} -> :ok
      account -> poll(account)
    end
  end

  defp poll(account) do
    with {:ok, account} <- ensure_fresh_token(account),
         {:ok, %{items: items, next_after: next_after}} <- recently_played_with_retry(account) do
      {:ok, _} = SyncService.sync_listens!(account, items, next_after)
      :ok
    else
      {:error, :broken} -> :ok
      {:error, {:rate_limited, retry_after}} -> {:snooze, retry_after}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_fresh_token(account) do
    if SpotifyAccount.token_expires_within?(account, @token_freshness_margin_in_seconds) do
      refresh_token(account)
    else
      {:ok, account}
    end
  end

  defp refresh_token(account) do
    case Client.refresh(account.refresh_token) do
      {:ok, token_data} -> SpotifyAccountService.update_tokens!(account, token_data)
      {:error, :invalid_grant} -> mark_broken(account)
      {:error, :unauthorized} -> mark_broken(account)
      {:error, reason} -> {:error, reason}
    end
  end

  # The refresh token no longer works, so polling can never succeed again.
  # Flag the account so the user can reconnect from the preferences page and
  # return :ok to avoid a retry storm.
  defp mark_broken(account) do
    {:ok, _} =
      account
      |> SpotifyAccount.changeset(%{broken_at: DateTime.utc_now()})
      |> Repo.update()

    {:error, :broken}
  end

  defp recently_played_with_retry(account) do
    case Client.recently_played(account.access_token, account.played_after_cursor) do
      {:error, :unauthorized} ->
        with {:ok, account} <- refresh_token(account) do
          Client.recently_played(account.access_token, account.played_after_cursor)
        end
      other ->
        other
    end
  end
end
