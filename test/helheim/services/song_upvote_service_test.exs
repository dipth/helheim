defmodule Helheim.SongUpvoteServiceTest do
  use Helheim.DataCase
  alias Helheim.SongUpvoteService
  alias Helheim.SongUpvote
  alias Helheim.Song

  ##############################################################################
  # upvote!/2
  describe "upvote!/2" do
    test "creates an upvote from the user on the song" do
      user = insert(:user)
      song = insert(:song)

      {:ok, %{song_upvote: upvote}} = SongUpvoteService.upvote!(song, user)

      assert upvote.user_id == user.id
      assert upvote.song_id == song.id
    end

    test "increments the upvotes_count of the song" do
      user = insert(:user)
      song = insert(:song, upvotes_count: 0)

      SongUpvoteService.upvote!(song, user)

      assert Repo.get(Song, song.id).upvotes_count == 1
    end

    test "does not create a second upvote or double increment when the user already upvoted" do
      user = insert(:user)
      song = insert(:song, upvotes_count: 0)

      {:ok, _} = SongUpvoteService.upvote!(song, user)
      {:error, :song_upvote, _changeset, _changes} = SongUpvoteService.upvote!(song, user)

      assert Repo.aggregate(SongUpvote, :count) == 1
      assert Repo.get(Song, song.id).upvotes_count == 1
    end

    test "lets different users each upvote the same song" do
      song = insert(:song, upvotes_count: 0)

      SongUpvoteService.upvote!(song, insert(:user))
      SongUpvoteService.upvote!(song, insert(:user))

      assert Repo.get(Song, song.id).upvotes_count == 2
    end
  end

  ##############################################################################
  # remove_upvote!/2
  describe "remove_upvote!/2" do
    test "removes the user's upvote and decrements the upvotes_count" do
      user = insert(:user)
      song = insert(:song, upvotes_count: 1)
      insert(:song_upvote, user: user, song: song)

      SongUpvoteService.remove_upvote!(song, user)

      refute Repo.exists?(from u in SongUpvote, where: u.user_id == ^user.id and u.song_id == ^song.id)
      assert Repo.get(Song, song.id).upvotes_count == 0
    end

    test "only removes the current user's upvote of the song" do
      user = insert(:user)
      song = insert(:song, upvotes_count: 2)
      insert(:song_upvote, user: user, song: song)
      other_upvote = insert(:song_upvote, song: song)
      my_other_upvote = insert(:song_upvote, user: user)

      SongUpvoteService.remove_upvote!(song, user)

      assert Repo.get(SongUpvote, other_upvote.id)
      assert Repo.get(SongUpvote, my_other_upvote.id)
      assert Repo.get(Song, song.id).upvotes_count == 1
    end

    test "does nothing when the user has not upvoted the song" do
      user = insert(:user)
      song = insert(:song, upvotes_count: 0)

      SongUpvoteService.remove_upvote!(song, user)

      assert Repo.get(Song, song.id).upvotes_count == 0
    end
  end

  ##############################################################################
  # delete_upvotes_for_user!/1
  describe "delete_upvotes_for_user!/1" do
    test "deletes all of the user's upvotes and decrements the counters of the affected songs" do
      user = insert(:user)
      song_1 = insert(:song, upvotes_count: 2)
      song_2 = insert(:song, upvotes_count: 1)
      insert(:song_upvote, user: user, song: song_1)
      other_upvote = insert(:song_upvote, song: song_1)
      insert(:song_upvote, user: user, song: song_2)

      {:ok, _} = SongUpvoteService.delete_upvotes_for_user!(user)

      refute Repo.exists?(from u in SongUpvote, where: u.user_id == ^user.id)
      assert Repo.get(SongUpvote, other_upvote.id)
      assert Repo.get(Song, song_1.id).upvotes_count == 1
      assert Repo.get(Song, song_2.id).upvotes_count == 0
    end

    test "does nothing for a user without upvotes" do
      song = insert(:song, upvotes_count: 1)
      insert(:song_upvote, song: song)

      {:ok, _} = SongUpvoteService.delete_upvotes_for_user!(insert(:user))

      assert Repo.get(Song, song.id).upvotes_count == 1
    end
  end

  ##############################################################################
  # upvoted_song_ids/2
  describe "upvoted_song_ids/2" do
    test "returns the subset of song ids the user has upvoted" do
      user = insert(:user)
      upvoted = insert(:song)
      not_upvoted = insert(:song)
      insert(:song_upvote, user: user, song: upvoted)

      assert SongUpvoteService.upvoted_song_ids(user, [upvoted.id, not_upvoted.id]) == [upvoted.id]
    end

    test "returns an empty list for a nil user or empty ids" do
      assert SongUpvoteService.upvoted_song_ids(nil, [1, 2]) == []
      assert SongUpvoteService.upvoted_song_ids(insert(:user), []) == []
    end
  end
end
