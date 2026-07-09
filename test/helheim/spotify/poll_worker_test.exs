defmodule Helheim.Spotify.PollWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  import Mock
  alias Helheim.Repo
  alias Helheim.SongListen
  alias Helheim.SpotifyAccount
  alias Helheim.Spotify.Client
  alias Helheim.Spotify.PollWorker

  @recently_played {:ok, %{
    items: [
      %{
        "track" => %{
          "id" => "track-abc",
          "name" => "Battery",
          "artists" => [%{"id" => "artist-1", "name" => "Metallica"}],
          "album" => %{"id" => "album-1", "name" => "Master of Puppets", "images" => []}
        },
        "played_at" => "2026-07-09T10:00:00.000Z"
      }
    ],
    next_after: 1_783_591_200_000
  }}

  @refreshed_token {:ok, %{"access_token" => "refreshed_access_token", "expires_in" => 3600}}

  test "polls spotify and stores the listens" do
    account = insert(:spotify_account)

    with_mock Client, [:passthrough], [recently_played: fn _token, _cursor -> @recently_played end] do
      assert :ok = perform_job(PollWorker, %{spotify_account_id: account.id})
      assert called Client.recently_played("an_access_token", nil)
    end

    assert Repo.aggregate(SongListen, :count) == 1
    account = Repo.get(SpotifyAccount, account.id)
    assert account.played_after_cursor == 1_783_591_200_000
    assert account.last_polled_at
  end

  test "polls with the stored cursor" do
    account = insert(:spotify_account, played_after_cursor: 123)

    with_mock Client, [:passthrough], [recently_played: fn _token, _cursor -> @recently_played end] do
      assert :ok = perform_job(PollWorker, %{spotify_account_id: account.id})
      assert called Client.recently_played("an_access_token", 123)
    end
  end

  test "refreshes the token first when it is about to expire" do
    account = insert(:spotify_account, token_expires_at: Timex.shift(Timex.now, seconds: 30))

    with_mock Client, [:passthrough], [
      refresh: fn "a_refresh_token" -> @refreshed_token end,
      recently_played: fn _token, _cursor -> @recently_played end
    ] do
      assert :ok = perform_job(PollWorker, %{spotify_account_id: account.id})
      assert called Client.recently_played("refreshed_access_token", nil)
    end

    assert Repo.get(SpotifyAccount, account.id).access_token == "refreshed_access_token"
  end

  test "refreshes the token and retries when spotify returns unauthorized" do
    account = insert(:spotify_account)

    with_mock Client, [:passthrough], [
      refresh: fn "a_refresh_token" -> @refreshed_token end,
      recently_played: fn
        "an_access_token", _cursor -> {:error, :unauthorized}
        "refreshed_access_token", _cursor -> @recently_played
      end
    ] do
      assert :ok = perform_job(PollWorker, %{spotify_account_id: account.id})
    end

    assert Repo.aggregate(SongListen, :count) == 1
  end

  test "marks the account as broken when the refresh token is rejected" do
    account = insert(:spotify_account)

    with_mock Client, [:passthrough], [
      refresh: fn "a_refresh_token" -> {:error, :invalid_grant} end,
      recently_played: fn _token, _cursor -> {:error, :unauthorized} end
    ] do
      assert :ok = perform_job(PollWorker, %{spotify_account_id: account.id})
    end

    assert Repo.get(SpotifyAccount, account.id).broken_at
    assert Repo.aggregate(SongListen, :count) == 0
  end

  test "snoozes when spotify rate limits the request" do
    account = insert(:spotify_account)

    with_mock Client, [:passthrough], [recently_played: fn _token, _cursor -> {:error, {:rate_limited, 30}} end] do
      assert {:snooze, 30} = perform_job(PollWorker, %{spotify_account_id: account.id})
    end
  end

  test "returns an error on unexpected failures so the job is retried" do
    account = insert(:spotify_account)

    with_mock Client, [:passthrough], [recently_played: fn _token, _cursor -> {:error, {:http_error, 500, %{}}} end] do
      assert {:error, _} = perform_job(PollWorker, %{spotify_account_id: account.id})
    end
  end

  test "skips accounts that no longer exist" do
    assert :ok = perform_job(PollWorker, %{spotify_account_id: 12_345_678})
  end

  test "skips broken accounts" do
    account = insert(:spotify_account, broken_at: DateTime.utc_now())

    with_mock Client, [:passthrough], [recently_played: fn _token, _cursor -> @recently_played end] do
      assert :ok = perform_job(PollWorker, %{spotify_account_id: account.id})
      assert not called Client.recently_played(:_, :_)
    end
  end
end
