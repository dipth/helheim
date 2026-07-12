defmodule Helheim.Lastfm.PollWorker do
  @moduledoc """
  Polls Last.fm for the scrobbles of a single connected account. Session
  keys never expire, so there is no token refresh; the connection is marked
  broken when Last.fm reports the session revoked, the user missing or the
  listening history hidden, and the user can reconnect from the preferences
  page.
  """

  use Oban.Worker,
    queue: :lastfm,
    max_attempts: 3,
    unique: [period: 240, keys: [:lastfm_account_id]]

  alias Helheim.Repo
  alias Helheim.LastfmAccount
  alias Helheim.Lastfm.Client
  alias Helheim.Lastfm.SyncService

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"lastfm_account_id" => lastfm_account_id}}) do
    case Repo.get(LastfmAccount, lastfm_account_id) do
      nil -> :ok
      %LastfmAccount{broken_at: %DateTime{}} -> :ok
      account -> poll(account)
    end
  end

  defp poll(account) do
    case Client.recent_tracks(account.username, account.session_key, account.played_after_cursor) do
      {:ok, %{tracks: tracks}} ->
        {:ok, _} = SyncService.sync_listens!(account, tracks)
        :ok
      {:error, reason} when reason in [:invalid_session, :hidden_history, :user_not_found] ->
        mark_broken(account)
      {:error, :rate_limited} ->
        {:snooze, 60}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Polling can never succeed again until the user reconnects (access
  # revoked, account gone or listening history hidden on Last.fm). Flag the
  # account and return :ok to avoid a retry storm.
  defp mark_broken(account) do
    {:ok, _} =
      account
      |> LastfmAccount.changeset(%{broken_at: DateTime.utc_now()})
      |> Repo.update()

    :ok
  end
end
