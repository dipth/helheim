defmodule Helheim.SpotifyAccountServiceTest do
  use Helheim.DataCase
  import Mock
  alias Helheim.SongListen
  alias Helheim.Song
  alias Helheim.SpotifyAccount
  alias Helheim.SpotifyAccountService
  alias Helheim.Spotify.Client

  @token_data %{
    "access_token" => "new_access_token",
    "refresh_token" => "new_refresh_token",
    "expires_in" => 3600,
    "scope" => "user-read-recently-played"
  }

  describe "connect!/2" do
    setup_with_mocks([
      {Client, [:passthrough], [me: fn _token -> {:ok, %{"id" => "spotify_uid"}} end]}
    ]) do
      {:ok, user: insert(:user)}
    end

    test "creates a spotify account for the user", %{user: user} do
      {:ok, account} = SpotifyAccountService.connect!(user, @token_data)
      assert account.user_id == user.id
      assert account.spotify_user_id == "spotify_uid"
      assert account.access_token == "new_access_token"
      assert account.refresh_token == "new_refresh_token"
      assert account.scopes == "user-read-recently-played"
      assert DateTime.compare(account.token_expires_at, DateTime.utc_now()) == :gt
    end

    test "updates the existing account and clears the broken state when reconnecting", %{user: user} do
      existing = insert(:spotify_account, user: user, broken_at: DateTime.utc_now(), played_after_cursor: 123)
      {:ok, account} = SpotifyAccountService.connect!(user, @token_data)
      assert account.id == existing.id
      assert account.access_token == "new_access_token"
      assert account.broken_at == nil
      assert account.played_after_cursor == nil
      assert Repo.aggregate(SpotifyAccount, :count) == 1
    end
  end

  describe "update_tokens!/2" do
    test "updates the tokens" do
      account = insert(:spotify_account)
      {:ok, account} = SpotifyAccountService.update_tokens!(account, @token_data)
      assert account.access_token == "new_access_token"
      assert account.refresh_token == "new_refresh_token"
    end

    test "keeps the existing refresh token when the response does not include one" do
      account = insert(:spotify_account, refresh_token: "old_refresh_token")
      {:ok, account} = SpotifyAccountService.update_tokens!(account, Map.delete(@token_data, "refresh_token"))
      assert account.access_token == "new_access_token"
      assert account.refresh_token == "old_refresh_token"
    end
  end

  describe "disconnect!/1" do
    test "deletes the spotify account but keeps the listens" do
      account = insert(:spotify_account)
      listen = insert(:song_listen, user: account.user)
      {:ok, _} = SpotifyAccountService.disconnect!(account.user)
      refute Repo.get(SpotifyAccount, account.id)
      assert Repo.get(SongListen, listen.id)
    end

    test "succeeds when the user has no spotify account" do
      assert {:ok, nil} = SpotifyAccountService.disconnect!(insert(:user))
    end
  end

  describe "delete_history!/1" do
    test "deletes all listens of the user and decrements the listen counters" do
      user = insert(:user)
      song_1 = insert(:song, listens_count: 3)
      song_2 = insert(:song, listens_count: 5)
      insert_list(2, :song_listen, user: user, song: song_1)
      insert(:song_listen, user: user, song: song_2)
      other_listen = insert(:song_listen, song: song_2)

      {:ok, _} = SpotifyAccountService.delete_history!(user)

      assert SongListen |> SongListen.for_user(user) |> Repo.aggregate(:count) == 0
      assert Repo.get(SongListen, other_listen.id)
      assert Repo.get(Song, song_1.id).listens_count == 1
      assert Repo.get(Song, song_2.id).listens_count == 4
    end
  end

  describe "delete_listens_for_song!/2" do
    test "deletes only the user's listens of that song and decrements its counter" do
      user = insert(:user)
      song = insert(:song, listens_count: 3)
      other_song = insert(:song, listens_count: 1)
      insert_list(2, :song_listen, user: user, song: song)
      my_other_listen = insert(:song_listen, user: user, song: other_song)
      other_listen = insert(:song_listen, song: song)

      {:ok, _} = SpotifyAccountService.delete_listens_for_song!(user, song)

      assert Repo.get(SongListen, my_other_listen.id)
      assert Repo.get(SongListen, other_listen.id)
      assert Repo.get(Song, song.id).listens_count == 1
      assert Repo.get(Song, other_song.id).listens_count == 1
    end
  end
end
