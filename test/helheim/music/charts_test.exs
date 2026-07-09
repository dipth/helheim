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
  end

  describe "start_of_day/0" do
    test "is midnight in Copenhagen expressed in UTC" do
      start_of_day = Charts.start_of_day()
      local = Timex.Timezone.convert(start_of_day, "Europe/Copenhagen")
      assert local.hour == 0
      assert local.minute == 0
      assert Timex.before?(start_of_day, Timex.now())
      assert Timex.diff(Timex.now(), start_of_day, :hours) < 25
    end
  end

  describe "start_of_week/0" do
    test "is monday midnight in Copenhagen expressed in UTC" do
      start_of_week = Charts.start_of_week()
      local = Timex.Timezone.convert(start_of_week, "Europe/Copenhagen")
      assert Timex.weekday(local) == 1
      assert local.hour == 0
      assert Timex.before?(start_of_week, Timex.now())
    end
  end
end
