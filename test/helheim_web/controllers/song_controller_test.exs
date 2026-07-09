defmodule HelheimWeb.SongControllerTest do
  use HelheimWeb.ConnCase

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response with the top songs of the week", %{conn: conn} do
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song)

      conn = get conn, "/songs"
      assert html_response(conn, 200) =~ "Creeping Death"
    end

    test "it does not include songs only listened to before this week", %{conn: conn} do
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, days: -8))

      conn = get conn, "/songs"
      refute html_response(conn, 200) =~ "Creeping Death"
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/songs"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the details of the song", %{conn: conn} do
      song = insert(:song, title: "Creeping Death", artist_name: "Metallica", album_name: "Ride the Lightning")

      conn = get conn, "/songs/#{song.id}"
      response = html_response(conn, 200)
      assert response =~ "Creeping Death"
      assert response =~ "Metallica"
      assert response =~ "Ride the Lightning"
      assert response =~ song.lastfm_track_url
      assert response =~ "https://www.last.fm/music/Metallica"
      assert response =~ "https://www.last.fm/music/Metallica/Ride%20the%20Lightning"
    end

    test "it shows the most recent listeners of the song", %{conn: conn} do
      song = insert(:song)
      listen = insert(:song_listen, song: song)

      conn = get conn, "/songs/#{song.id}"
      assert html_response(conn, 200) =~ listen.user.username
    end

    test "it shows the comments of the song", %{conn: conn} do
      comment = insert(:song_comment, body: "What a fantastic track")

      conn = get conn, "/songs/#{comment.song_id}"
      assert html_response(conn, 200) =~ "What a fantastic track"
    end

    test "it returns a 404 when the song does not exist", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/songs/1234567"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      song = insert(:song)
      conn = get conn, "/songs/#{song.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # remove_my_listens/2
  describe "remove_my_listens/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it deletes only the current user's listens of the song and decrements its counter", %{conn: conn, user: user} do
      song = insert(:song, listens_count: 2)
      my_listen = insert(:song_listen, user: user, song: song)
      other_listen = insert(:song_listen, song: song)
      my_other_listen = insert(:song_listen, user: user)

      conn = delete conn, "/songs/#{song.id}/my_listens"
      assert redirected_to(conn) == song_path(conn, :show, song)
      refute Repo.get(Helheim.SongListen, my_listen.id)
      assert Repo.get(Helheim.SongListen, other_listen.id)
      assert Repo.get(Helheim.SongListen, my_other_listen.id)
      assert Repo.get(Helheim.Song, song.id).listens_count == 1
    end

    test "it shows the remove button only when the current user has listens on the song", %{conn: conn, user: user} do
      song = insert(:song)
      conn_without = get conn, "/songs/#{song.id}"
      refute html_response(conn_without, 200) =~ gettext("Remove my name from this song")

      insert(:song_listen, user: user, song: song)
      conn_with = get conn, "/songs/#{song.id}"
      assert html_response(conn_with, 200) =~ gettext("Remove my name from this song")
    end

    test "it returns a 404 when the song does not exist", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        delete conn, "/songs/1234567/my_listens"
      end
    end
  end

  describe "remove_my_listens/2 when not signed in" do
    test "it redirects to the sign in page and does not delete any listens", %{conn: conn} do
      listen = insert(:song_listen)
      conn = delete conn, "/songs/#{listen.song_id}/my_listens"
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert Repo.get(Helheim.SongListen, listen.id)
    end
  end
end
