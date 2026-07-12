defmodule Helheim.Lastfm.SyncServiceTest do
  use Helheim.DataCase
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.LastfmAccount
  alias Helheim.Lastfm.SyncService

  @uts_10_00 1_783_591_200
  @uts_11_00 1_783_594_800

  setup do
    [account: insert(:lastfm_account)]
  end

  defp item(title, uts, overrides \\ %{}) do
    Map.merge(%{
      "name" => title,
      "mbid" => "",
      "url" => "https://www.last.fm/music/Metallica/_/#{URI.encode(title)}",
      "artist" => %{"#text" => "Metallica", "mbid" => ""},
      "album" => %{"#text" => "Ride the Lightning", "mbid" => ""},
      "image" => [
        %{"size" => "small", "#text" => "https://lastfm.freetls.fastly.net/i/u/34s/abc.jpg"},
        %{"size" => "medium", "#text" => "https://lastfm.freetls.fastly.net/i/u/64s/abc.jpg"},
        %{"size" => "large", "#text" => "https://lastfm.freetls.fastly.net/i/u/174s/abc.jpg"},
        %{"size" => "extralarge", "#text" => "https://lastfm.freetls.fastly.net/i/u/300x300/abc.jpg"}
      ],
      "date" => %{"uts" => "#{uts}", "#text" => "09 Jul 2026, 10:00"}
    }, overrides)
  end

  describe "sync_listens!/2" do
    test "creates a song with the track metadata and a listen for the user", %{account: account} do
      {:ok, _} = SyncService.sync_listens!(account, [item("For Whom the Bell Tolls", @uts_10_00)])

      song = Repo.get_by!(Song, title: "For Whom the Bell Tolls")
      assert song.artist_name == "Metallica"
      assert song.album_name == "Ride the Lightning"
      assert song.cover_image_url == "https://lastfm.freetls.fastly.net/i/u/300x300/abc.jpg"
      assert song.cover_image_url_small == "https://lastfm.freetls.fastly.net/i/u/64s/abc.jpg"
      assert song.lastfm_track_url == "https://www.last.fm/music/Metallica/_/For%20Whom%20the%20Bell%20Tolls"
      assert song.listens_count == 1

      listen = Repo.get_by!(SongListen, song_id: song.id)
      assert listen.user_id == account.user_id
      assert listen.played_at == DateTime.from_unix!(@uts_10_00) |> Map.put(:microsecond, {0, 6})
    end

    test "reuses an existing song with the same artist and title ignoring case", %{account: account} do
      song = insert(:song, artist_name: "METALLICA", title: "for whom the bell tolls", listens_count: 7)

      {:ok, _} = SyncService.sync_listens!(account, [item("For Whom the Bell Tolls", @uts_10_00)])

      assert Repo.aggregate(Song, :count) == 1
      song = Repo.get(Song, song.id)
      assert song.title == "For Whom the Bell Tolls"
      assert song.artist_name == "Metallica"
      assert song.listens_count == 8
    end

    test "does not clobber existing metadata when a later scrobble lacks it", %{account: account} do
      song = insert(:song, artist_name: "Metallica", title: "For Whom the Bell Tolls")

      bare = item("For Whom the Bell Tolls", @uts_10_00, %{"album" => %{"#text" => ""}, "image" => [], "url" => ""})
      {:ok, _} = SyncService.sync_listens!(account, [bare])

      updated = Repo.get(Song, song.id)
      assert updated.album_name == song.album_name
      assert updated.cover_image_url == song.cover_image_url
      assert updated.cover_image_url_small == song.cover_image_url_small
      assert updated.lastfm_track_url == song.lastfm_track_url
    end

    test "stores the placeholder cover art as no cover", %{account: account} do
      placeholder = "https://lastfm.freetls.fastly.net/i/u/300x300/2a96cbd8b46e442fc41c2b86b821562f.png"
      images = [
        %{"size" => "medium", "#text" => placeholder},
        %{"size" => "extralarge", "#text" => placeholder}
      ]
      {:ok, _} = SyncService.sync_listens!(account, [item("Orion", @uts_10_00, %{"image" => images})])

      song = Repo.get_by!(Song, title: "Orion")
      assert song.cover_image_url == nil
      assert song.cover_image_url_small == nil
    end

    test "stores a blank album as no album", %{account: account} do
      {:ok, _} = SyncService.sync_listens!(account, [item("Orion", @uts_10_00, %{"album" => %{"#text" => ""}})])
      assert Repo.get_by!(Song, title: "Orion").album_name == nil
    end

    test "is idempotent for listens with the same user and played_at", %{account: account} do
      items = [item("Orion", @uts_10_00)]
      {:ok, _} = SyncService.sync_listens!(account, items)
      {:ok, _} = SyncService.sync_listens!(account, items)

      assert Repo.aggregate(SongListen, :count) == 1
      assert Repo.get_by!(Song, title: "Orion").listens_count == 1
    end

    test "allows different users to listen at the same timestamp", %{account: account} do
      other_account = insert(:lastfm_account)
      items = [item("Orion", @uts_10_00)]
      {:ok, _} = SyncService.sync_listens!(account, items)
      {:ok, _} = SyncService.sync_listens!(other_account, items)

      assert Repo.aggregate(SongListen, :count) == 2
      assert Repo.get_by!(Song, title: "Orion").listens_count == 2
    end

    test "allows two different songs scrobbled at the same timestamp", %{account: account} do
      items = [item("Orion", @uts_10_00), item("Battery", @uts_10_00)]
      {:ok, _} = SyncService.sync_listens!(account, items)

      assert Repo.aggregate(SongListen, :count) == 2
      assert Repo.get_by!(Song, title: "Orion").listens_count == 1
      assert Repo.get_by!(Song, title: "Battery").listens_count == 1
    end

    test "skips items with a malformed artist or image payload without crashing the batch", %{account: account} do
      items = [
        item("Orion", @uts_10_00, %{"artist" => "Metallica"}),
        item("Battery", @uts_11_00, %{"image" => "not a list", "album" => "not a map"})
      ]
      {:ok, _} = SyncService.sync_listens!(account, items)

      refute Repo.get_by(Song, title: "Orion")
      song = Repo.get_by!(Song, title: "Battery")
      assert song.cover_image_url == nil
      assert song.album_name == nil
    end

    test "skips the currently playing track", %{account: account} do
      nowplaying =
        item("Orion", @uts_10_00)
        |> Map.put("@attr", %{"nowplaying" => "true"})
        |> Map.delete("date")

      {:ok, _} = SyncService.sync_listens!(account, [nowplaying, item("Battery", @uts_11_00)])

      assert Repo.aggregate(SongListen, :count) == 1
      refute Repo.get_by(Song, title: "Orion")
      assert Repo.get_by(Song, title: "Battery")
    end

    test "skips items without a parsable date or blank name/artist", %{account: account} do
      items = [
        item("Orion", @uts_10_00, %{"date" => %{"uts" => "not a timestamp"}}),
        item("", @uts_10_00),
        item("Escape", @uts_10_00, %{"artist" => %{"#text" => ""}}),
        Map.delete(item("Trapped Under Ice", @uts_10_00), "date"),
        item("Battery", @uts_11_00)
      ]
      {:ok, _} = SyncService.sync_listens!(account, items)

      assert Repo.aggregate(SongListen, :count) == 1
      assert Repo.get_by(Song, title: "Battery")
    end

    test "updates the polling cursor to the newest played_at and sets last_polled_at", %{account: account} do
      items = [item("Orion", @uts_10_00), item("Battery", @uts_11_00)]
      {:ok, _} = SyncService.sync_listens!(account, items)

      account = Repo.get(LastfmAccount, account.id)
      assert account.played_after_cursor == @uts_11_00
      assert account.last_polled_at
    end

    test "keeps the existing cursor when there are no items", %{account: account} do
      {:ok, existing} = account |> LastfmAccount.changeset(%{played_after_cursor: 123}) |> Repo.update()
      {:ok, _} = SyncService.sync_listens!(existing, [])

      account = Repo.get(LastfmAccount, account.id)
      assert account.played_after_cursor == 123
      assert account.last_polled_at
    end
  end
end
