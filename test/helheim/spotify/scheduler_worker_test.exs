defmodule Helheim.Spotify.SchedulerWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  alias Helheim.Spotify.PollWorker
  alias Helheim.Spotify.SchedulerWorker

  test "enqueues one poll job per working spotify account" do
    account_1 = insert(:spotify_account)
    account_2 = insert(:spotify_account)

    assert :ok = perform_job(SchedulerWorker, %{})

    assert_enqueued worker: PollWorker, args: %{spotify_account_id: account_1.id}
    assert_enqueued worker: PollWorker, args: %{spotify_account_id: account_2.id}
  end

  test "does not enqueue poll jobs for broken accounts" do
    account = insert(:spotify_account, broken_at: DateTime.utc_now())

    assert :ok = perform_job(SchedulerWorker, %{})

    refute_enqueued worker: PollWorker, args: %{spotify_account_id: account.id}
  end
end
