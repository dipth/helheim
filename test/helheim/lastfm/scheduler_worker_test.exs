defmodule Helheim.Lastfm.SchedulerWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  alias Helheim.Lastfm.PollWorker
  alias Helheim.Lastfm.SchedulerWorker

  test "enqueues one poll job per working lastfm account" do
    account_1 = insert(:lastfm_account)
    account_2 = insert(:lastfm_account)

    assert :ok = perform_job(SchedulerWorker, %{})

    assert_enqueued worker: PollWorker, args: %{lastfm_account_id: account_1.id}
    assert_enqueued worker: PollWorker, args: %{lastfm_account_id: account_2.id}
  end

  test "does not enqueue poll jobs for broken accounts" do
    account = insert(:lastfm_account, broken_at: DateTime.utc_now())

    assert :ok = perform_job(SchedulerWorker, %{})

    refute_enqueued worker: PollWorker, args: %{lastfm_account_id: account.id}
  end
end
