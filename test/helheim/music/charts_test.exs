defmodule Helheim.Music.ChartsTest do
  use Helheim.DataCase
  alias Helheim.Music.Charts

  describe "top_songs_since/2" do
    test "orders songs by number of listens since the given time and excludes older listens" do
      since = Timex.shift(Timex.now, days: -1)
      song_1 = insert(:song)
      song_2 = insert(:song)
      song_3 = insert(:song)
      insert(:song_listen, song: song_1)
      insert_list(2, :song_listen, song: song_2)
      insert(:song_listen, song: song_3, played_at: Timex.shift(Timex.now, days: -2))

      results = Charts.top_songs_since(since, 10)

      assert [{top_song, 2}, {runner_up, 1}] = results
      assert top_song.id == song_2.id
      assert runner_up.id == song_1.id
    end

    test "limits the number of results" do
      insert_list(3, :song_listen)
      assert length(Charts.top_songs_since(Timex.shift(Timex.now, days: -1), 2)) == 2
    end

    test "excludes listens from the given user ids" do
      since = Timex.shift(Timex.now, days: -1)
      ignoree = insert(:user)
      song = insert(:song)
      insert(:song_listen, user: ignoree, song: song)
      other_listen = insert(:song_listen)

      results = Charts.top_songs_since(since, 10, [ignoree.id])

      assert [{top_song, 1}] = results
      assert top_song.id == other_listen.song_id
    end
  end

  describe "top_songs_last_day/2" do
    test "includes listens from the past 24 hours and excludes older ones" do
      song = insert(:song)
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, hours: -23))
      old_song = insert(:song)
      insert(:song_listen, song: old_song, played_at: Timex.shift(Timex.now, hours: -25))

      results = Charts.top_songs_last_day(10)

      assert [{top_song, 1}] = results
      assert top_song.id == song.id
    end
  end

  describe "top_songs_last_week/2" do
    test "includes listens from the past 7 days and excludes older ones" do
      song = insert(:song)
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, days: -6))
      old_song = insert(:song)
      insert(:song_listen, song: old_song, played_at: Timex.shift(Timex.now, days: -8))

      results = Charts.top_songs_last_week(10)

      assert [{top_song, 1}] = results
      assert top_song.id == song.id
    end
  end

  describe "top_upvoted_songs_since/2" do
    test "orders songs by number of upvotes since the given time and excludes older upvotes" do
      since = Timex.shift(Timex.now, days: -1)
      song_1 = insert(:song)
      song_2 = insert(:song)
      song_3 = insert(:song)
      insert(:song_upvote, song: song_1)
      insert_list(2, :song_upvote, song: song_2)
      insert(:song_upvote, song: song_3, inserted_at: Timex.shift(Timex.now, days: -2))

      results = Charts.top_upvoted_songs_since(since, 10)

      assert [{top_song, 2}, {runner_up, 1}] = results
      assert top_song.id == song_2.id
      assert runner_up.id == song_1.id
    end

    test "limits the number of results" do
      insert_list(3, :song_upvote)
      assert length(Charts.top_upvoted_songs_since(Timex.shift(Timex.now, days: -1), 2)) == 2
    end

    test "excludes upvotes from the given user ids" do
      since = Timex.shift(Timex.now, days: -1)
      ignoree = insert(:user)
      song = insert(:song)
      insert(:song_upvote, user: ignoree, song: song)
      other_upvote = insert(:song_upvote)

      results = Charts.top_upvoted_songs_since(since, 10, [ignoree.id])

      assert [{top_song, 1}] = results
      assert top_song.id == other_upvote.song_id
    end
  end

  describe "top_upvoted_songs_last_day/2" do
    test "includes upvotes from the past 24 hours and excludes older ones" do
      song = insert(:song)
      insert(:song_upvote, song: song, inserted_at: Timex.shift(Timex.now, hours: -23))
      old_song = insert(:song)
      insert(:song_upvote, song: old_song, inserted_at: Timex.shift(Timex.now, hours: -25))

      results = Charts.top_upvoted_songs_last_day(10)

      assert [{top_song, 1}] = results
      assert top_song.id == song.id
    end
  end

  describe "top_upvoted_songs_last_week/2" do
    test "includes upvotes from the past 7 days and excludes older ones" do
      song = insert(:song)
      insert(:song_upvote, song: song, inserted_at: Timex.shift(Timex.now, days: -6))
      old_song = insert(:song)
      insert(:song_upvote, song: old_song, inserted_at: Timex.shift(Timex.now, days: -8))

      results = Charts.top_upvoted_songs_last_week(10)

      assert [{top_song, 1}] = results
      assert top_song.id == song.id
    end
  end
end
