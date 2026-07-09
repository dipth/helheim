defmodule Helheim.Lastfm.PollWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  import Mock
  alias Helheim.Repo
  alias Helheim.SongListen
  alias Helheim.LastfmAccount
  alias Helheim.Lastfm.Client
  alias Helheim.Lastfm.PollWorker

  @recent_tracks {:ok, %{
    tracks: [
      %{
        "name" => "Battery",
        "url" => "https://www.last.fm/music/Metallica/_/Battery",
        "artist" => %{"#text" => "Metallica"},
        "album" => %{"#text" => "Master of Puppets"},
        "image" => [],
        "date" => %{"uts" => "1783591200"}
      }
    ]
  }}

  test "polls last.fm and stores the listens" do
    account = insert(:lastfm_account)

    with_mock Client, [:passthrough], [recent_tracks: fn _username, _sk, _from -> @recent_tracks end] do
      assert :ok = perform_job(PollWorker, %{lastfm_account_id: account.id})
      assert called Client.recent_tracks(account.username, "a_session_key", nil)
    end

    assert Repo.aggregate(SongListen, :count) == 1
    account = Repo.get(LastfmAccount, account.id)
    assert account.played_after_cursor == 1_783_591_200
    assert account.last_polled_at
  end

  test "polls with the stored cursor" do
    account = insert(:lastfm_account, played_after_cursor: 123)

    with_mock Client, [:passthrough], [recent_tracks: fn _username, _sk, _from -> @recent_tracks end] do
      assert :ok = perform_job(PollWorker, %{lastfm_account_id: account.id})
      assert called Client.recent_tracks(account.username, "a_session_key", 123)
    end
  end

  for reason <- [:invalid_session, :hidden_history, :user_not_found] do
    test "marks the account as broken on #{reason}" do
      account = insert(:lastfm_account)

      with_mock Client, [:passthrough], [recent_tracks: fn _username, _sk, _from -> {:error, unquote(reason)} end] do
        assert :ok = perform_job(PollWorker, %{lastfm_account_id: account.id})
      end

      assert Repo.get(LastfmAccount, account.id).broken_at
      assert Repo.aggregate(SongListen, :count) == 0
    end
  end

  test "snoozes when last.fm rate limits the request" do
    account = insert(:lastfm_account)

    with_mock Client, [:passthrough], [recent_tracks: fn _username, _sk, _from -> {:error, :rate_limited} end] do
      assert {:snooze, 60} = perform_job(PollWorker, %{lastfm_account_id: account.id})
    end

    refute Repo.get(LastfmAccount, account.id).broken_at
  end

  test "returns an error on unexpected failures so the job is retried" do
    account = insert(:lastfm_account)

    with_mock Client, [:passthrough], [recent_tracks: fn _username, _sk, _from -> {:error, {:api_error, 16, "temporary error"}} end] do
      assert {:error, _} = perform_job(PollWorker, %{lastfm_account_id: account.id})
    end

    refute Repo.get(LastfmAccount, account.id).broken_at
  end

  test "skips accounts that no longer exist" do
    assert :ok = perform_job(PollWorker, %{lastfm_account_id: 12_345_678})
  end

  test "skips broken accounts" do
    account = insert(:lastfm_account, broken_at: DateTime.utc_now())

    with_mock Client, [:passthrough], [recent_tracks: fn _username, _sk, _from -> @recent_tracks end] do
      assert :ok = perform_job(PollWorker, %{lastfm_account_id: account.id})
      assert not called Client.recent_tracks(:_, :_, :_)
    end
  end
end
