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
      assert response =~ song.spotify_track_url
      assert response =~ song.spotify_artist_url
      assert response =~ song.spotify_album_url
    end

    test "it shows the most recent listeners of the song", %{conn: conn} do
      song = insert(:song)
      listen = insert(:song_listen, song: song)

      conn = get conn, "/songs/#{song.id}"
      assert html_response(conn, 200) =~ listen.user.username
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
end
