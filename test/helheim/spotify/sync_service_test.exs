defmodule Helheim.Spotify.SyncServiceTest do
  use Helheim.DataCase
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.SpotifyAccount
  alias Helheim.Spotify.SyncService

  setup do
    [account: insert(:spotify_account)]
  end

  defp item(track_id, played_at, overrides \\ %{}) do
    Map.merge(%{
      "track" => %{
        "id" => track_id,
        "name" => "For Whom the Bell Tolls",
        "duration_ms" => 310_000,
        "preview_url" => "https://p.scdn.co/mp3-preview/abc",
        "external_urls" => %{"spotify" => "https://open.spotify.com/track/#{track_id}"},
        "artists" => [
          %{
            "id" => "artist-1",
            "name" => "Metallica",
            "external_urls" => %{"spotify" => "https://open.spotify.com/artist/artist-1"}
          }
        ],
        "album" => %{
          "id" => "album-1",
          "name" => "Ride the Lightning",
          "external_urls" => %{"spotify" => "https://open.spotify.com/album/album-1"},
          "images" => [
            %{"height" => 640, "width" => 640, "url" => "https://i.scdn.co/image/640.jpg"},
            %{"height" => 300, "width" => 300, "url" => "https://i.scdn.co/image/300.jpg"},
            %{"height" => 64, "width" => 64, "url" => "https://i.scdn.co/image/64.jpg"}
          ]
        }
      },
      "played_at" => played_at
    }, overrides)
  end

  describe "sync_listens!/3" do
    test "creates a song with the track metadata and a listen for the user", %{account: account} do
      {:ok, _} = SyncService.sync_listens!(account, [item("track-abc", "2026-07-09T10:00:00.000Z")])

      song = Repo.get_by!(Song, spotify_track_id: "track-abc")
      assert song.title == "For Whom the Bell Tolls"
      assert song.artist_name == "Metallica"
      assert song.artist_spotify_id == "artist-1"
      assert song.album_name == "Ride the Lightning"
      assert song.cover_image_url == "https://i.scdn.co/image/300.jpg"
      assert song.cover_image_url_small == "https://i.scdn.co/image/64.jpg"
      assert song.spotify_track_url == "https://open.spotify.com/track/track-abc"
      assert song.spotify_artist_url == "https://open.spotify.com/artist/artist-1"
      assert song.spotify_album_url == "https://open.spotify.com/album/album-1"
      assert song.duration_ms == 310_000
      assert song.listens_count == 1

      listen = Repo.get_by!(SongListen, song_id: song.id)
      assert listen.user_id == account.user_id
      assert listen.played_at == ~U[2026-07-09 10:00:00.000000Z]
    end

    test "reuses and refreshes an existing song with the same spotify track id", %{account: account} do
      song = insert(:song, spotify_track_id: "track-abc", title: "Old Title", listens_count: 7)

      {:ok, _} = SyncService.sync_listens!(account, [item("track-abc", "2026-07-09T10:00:00.000Z")])

      assert Repo.aggregate(Song, :count) == 1
      song = Repo.get(Song, song.id)
      assert song.title == "For Whom the Bell Tolls"
      assert song.listens_count == 8
    end

    test "is idempotent for listens with the same user and played_at", %{account: account} do
      items = [item("track-abc", "2026-07-09T10:00:00.000Z")]
      {:ok, _} = SyncService.sync_listens!(account, items)
      {:ok, _} = SyncService.sync_listens!(account, items)

      assert Repo.aggregate(SongListen, :count) == 1
      assert Repo.get_by!(Song, spotify_track_id: "track-abc").listens_count == 1
    end

    test "allows different users to listen at the same timestamp", %{account: account} do
      other_account = insert(:spotify_account)
      items = [item("track-abc", "2026-07-09T10:00:00.000Z")]
      {:ok, _} = SyncService.sync_listens!(account, items)
      {:ok, _} = SyncService.sync_listens!(other_account, items)

      assert Repo.aggregate(SongListen, :count) == 2
      assert Repo.get_by!(Song, spotify_track_id: "track-abc").listens_count == 2
    end

    test "skips non-track items and unparsable timestamps", %{account: account} do
      items = [
        %{"track" => nil, "played_at" => "2026-07-09T10:00:00.000Z"},
        %{"episode" => %{"id" => "episode-1"}},
        item("track-abc", "not a timestamp"),
        item("track-def", "2026-07-09T10:00:00.000Z")
      ]
      {:ok, _} = SyncService.sync_listens!(account, items)

      assert Repo.aggregate(SongListen, :count) == 1
      assert Repo.get_by(Song, spotify_track_id: "track-def")
      refute Repo.get_by(Song, spotify_track_id: "track-abc")
    end

    test "updates the polling cursor and last_polled_at from the given cursor", %{account: account} do
      {:ok, _} = SyncService.sync_listens!(account, [item("track-abc", "2026-07-09T10:00:00.000Z")], 1_783_591_200_000)

      account = Repo.get(SpotifyAccount, account.id)
      assert account.played_after_cursor == 1_783_591_200_000
      assert account.last_polled_at
    end

    test "falls back to the newest played_at when no cursor is given", %{account: account} do
      items = [
        item("track-abc", "2026-07-09T10:00:00.000Z"),
        item("track-def", "2026-07-09T11:00:00.000Z")
      ]
      {:ok, _} = SyncService.sync_listens!(account, items)

      account = Repo.get(SpotifyAccount, account.id)
      assert account.played_after_cursor == DateTime.to_unix(~U[2026-07-09 11:00:00.000Z], :millisecond)
    end

    test "keeps the existing cursor when there are no items", %{account: account} do
      {:ok, existing} = account |> SpotifyAccount.changeset(%{played_after_cursor: 123}) |> Repo.update()
      {:ok, _} = SyncService.sync_listens!(existing, [])

      account = Repo.get(SpotifyAccount, account.id)
      assert account.played_after_cursor == 123
      assert account.last_polled_at
    end
  end
end
