defmodule Helheim.LastfmAccountServiceTest do
  use Helheim.DataCase
  alias Helheim.SongListen
  alias Helheim.Song
  alias Helheim.LastfmAccount
  alias Helheim.LastfmAccountService

  @session %{username: "melomaniac", session_key: "new_session_key"}

  describe "connect!/2" do
    test "creates a lastfm account for the user with a from-now cursor" do
      user = insert(:user)
      {:ok, account} = LastfmAccountService.connect!(user, @session)
      assert account.user_id == user.id
      assert account.username == "melomaniac"
      assert account.session_key == "new_session_key"
      assert_in_delta account.played_after_cursor, DateTime.to_unix(DateTime.utc_now()), 10
    end

    test "updates the existing account, clears the broken state and keeps the cursor when reconnecting the same account" do
      user = insert(:user)
      existing = insert(:lastfm_account, user: user, username: "MeloManiac", broken_at: DateTime.utc_now(), played_after_cursor: 123)
      {:ok, account} = LastfmAccountService.connect!(user, @session)
      assert account.id == existing.id
      assert account.username == "melomaniac"
      assert account.session_key == "new_session_key"
      assert account.broken_at == nil
      assert account.played_after_cursor == 123
      assert Repo.aggregate(LastfmAccount, :count) == 1
    end

    test "resets the cursor when connecting a different lastfm account" do
      user = insert(:user)
      insert(:lastfm_account, user: user, username: "somebody_else", played_after_cursor: 123)
      {:ok, account} = LastfmAccountService.connect!(user, @session)
      assert account.username == "melomaniac"
      assert_in_delta account.played_after_cursor, DateTime.to_unix(DateTime.utc_now()), 10
    end

    test "returns an error changeset instead of raising when the user already has an account row" do
      user = insert(:user)
      insert(:lastfm_account, user: user)

      {:error, changeset} =
        %Helheim.LastfmAccount{}
        |> Helheim.LastfmAccount.changeset(%{username: "melomaniac", session_key: "key"})
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Repo.insert()

      assert {"has already been taken", _} = changeset.errors[:user_id]
    end
  end

  describe "disconnect!/1" do
    test "deletes the lastfm account but keeps the listens" do
      account = insert(:lastfm_account)
      listen = insert(:song_listen, user: account.user)
      {:ok, _} = LastfmAccountService.disconnect!(account.user)
      refute Repo.get(LastfmAccount, account.id)
      assert Repo.get(SongListen, listen.id)
    end

    test "succeeds when the user has no lastfm account" do
      assert {:ok, nil} = LastfmAccountService.disconnect!(insert(:user))
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

      {:ok, _} = LastfmAccountService.delete_history!(user)

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

      {:ok, _} = LastfmAccountService.delete_listens_for_song!(user, song)

      assert Repo.get(SongListen, my_other_listen.id)
      assert Repo.get(SongListen, other_listen.id)
      assert Repo.get(Song, song.id).listens_count == 1
      assert Repo.get(Song, other_song.id).listens_count == 1
    end
  end
end
