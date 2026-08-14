defmodule Helheim.Music.StatsTest do
  use Helheim.DataCase
  alias Helheim.Music.Stats

  describe "top_genres/1" do
    test "orders genres by the total listens of the songs they are the primary tag of" do
      thrash = insert(:tag, name: "thrash metal")
      doom = insert(:tag, name: "doom metal")
      insert(:song_tag, song: insert(:song, listens_count: 3), tag: thrash)
      insert(:song_tag, song: insert(:song, listens_count: 4), tag: thrash)
      insert(:song_tag, song: insert(:song, listens_count: 5), tag: doom)

      assert [{top, 7}, {runner_up, 5}] = Stats.top_genres(10)
      assert top.id == thrash.id
      assert runner_up.id == doom.id
    end

    test "does not count a tag that is not the song's primary tag" do
      secondary = insert(:tag, name: "live")
      insert(:song_tag, song: insert(:song, listens_count: 9), tag: secondary, position: 2)

      assert Stats.top_genres(10) == []
    end

    test "does not include a genre whose songs have never been played" do
      insert(:song_tag, song: insert(:song, listens_count: 0), tag: insert(:tag))

      assert Stats.top_genres(10) == []
    end

    test "limits the number of results" do
      for _ <- 1..3 do
        insert(:song_tag, song: insert(:song, listens_count: 1), tag: insert(:tag))
      end

      assert length(Stats.top_genres(2)) == 2
    end
  end

  describe "top_artists/1" do
    test "sums the listens of every song by the same artist" do
      insert(:song, artist_name: "Metallica", listens_count: 2)
      insert(:song, artist_name: "Metallica", listens_count: 3)
      insert(:song, artist_name: "Bathory", listens_count: 4)

      assert [{"Metallica", 5, _}, {"Bathory", 4, _}] = Stats.top_artists(10)
    end

    test "treats artist names that differ only in casing as the same artist" do
      insert(:song, artist_name: "Metallica", listens_count: 2)
      insert(:song, artist_name: "metallica", listens_count: 3)

      assert [{_name, 5, _artist}] = Stats.top_artists(10)
    end

    test "attaches the enriched artist record when there is one" do
      insert(:song, artist_name: "Bathory", listens_count: 1)
      artist = insert(:artist, name: "Bathory")

      assert [{"Bathory", 1, %Helheim.Artist{} = found}] = Stats.top_artists(10)
      assert found.id == artist.id
    end

    test "returns artists without an enriched record too" do
      insert(:song, artist_name: "Bathory", listens_count: 1)

      assert [{"Bathory", 1, nil}] = Stats.top_artists(10)
    end

    test "does not include songs that have never been played" do
      insert(:song, artist_name: "Bathory", listens_count: 0)

      assert Stats.top_artists(10) == []
    end

    test "limits the number of results" do
      insert(:song, artist_name: "Metallica", listens_count: 1)
      insert(:song, artist_name: "Bathory", listens_count: 1)
      insert(:song, artist_name: "Mayhem", listens_count: 1)

      assert length(Stats.top_artists(2)) == 2
    end
  end

  describe "listens_per_decade/0" do
    test "buckets release years into decades, ascending" do
      insert(:song, release_year: 1986, listens_count: 2)
      insert(:song, release_year: 1988, listens_count: 3)
      insert(:song, release_year: 1994, listens_count: 1)

      assert Stats.listens_per_decade() == [{1980, 5}, {1990, 1}]
    end

    test "leaves out songs with no release year" do
      insert(:song, release_year: nil, listens_count: 4)

      assert Stats.listens_per_decade() == []
    end

    test "leaves out implausible release years from bad metadata" do
      insert(:song, release_year: 3025, listens_count: 4)

      assert Stats.listens_per_decade() == []
    end

    test "leaves out songs that have never been played" do
      insert(:song, release_year: 1986, listens_count: 0)

      assert Stats.listens_per_decade() == []
    end
  end

  describe "totals/0" do
    test "returns zeroes when nothing has been tracked yet" do
      assert Stats.totals() == %{songs: 0, artists: 0, listens: 0, upvotes: 0, listeners: 0}
    end

    test "counts songs, artists, listens and upvotes" do
      song = insert(:song, artist_name: "Metallica", listens_count: 3, upvotes_count: 2)
      insert(:song, artist_name: "Bathory", listens_count: 1, upvotes_count: 0)
      insert(:song_listen, song: song)

      totals = Stats.totals()
      assert totals.songs == 2
      assert totals.artists == 2
      assert totals.listens == 4
      assert totals.upvotes == 2
    end

    test "counts each listener only once" do
      listener = insert(:user)
      song = insert(:song)
      insert(:song_listen, user: listener, song: song, played_at: Timex.shift(Timex.now, minutes: -10))
      insert(:song_listen, user: listener, song: song, played_at: Timex.shift(Timex.now, minutes: -5))

      assert Stats.totals().listeners == 1
    end

    test "counts artist names that differ only in casing as one artist" do
      insert(:song, artist_name: "Metallica")
      insert(:song, artist_name: "metallica")

      assert Stats.totals().artists == 1
    end
  end
end
