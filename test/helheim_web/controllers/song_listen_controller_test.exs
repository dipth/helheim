defmodule HelheimWeb.SongListenControllerTest do
  use HelheimWeb.ConnCase

  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the listens, top songs and top artists of the profile", %{conn: conn} do
      profile = insert(:user)
      song = insert(:song, title: "Creeping Death", artist_name: "Metallica")
      insert(:song_listen, user: profile, song: song)

      conn = get conn, "/profiles/#{profile.id}/music"
      response = html_response(conn, 200)
      assert response =~ "Creeping Death"
      assert response =~ "Metallica"
    end

    test "it does not show listens from other users", %{conn: conn} do
      profile = insert(:user)
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song)

      conn = get conn, "/profiles/#{profile.id}/music"
      refute html_response(conn, 200) =~ "Creeping Death"
    end

    test "it redirects to the block page if the specified profile blocks the current user", %{conn: conn, user: user} do
      profile = insert(:user)
      insert(:block, blocker: profile, blockee: user)

      conn = get conn, "/profiles/#{profile.id}/music"
      assert redirected_to(conn) == block_path(conn, :show, profile)
    end

    test "it returns a 404 when the profile does not exist", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/1234567/music"
      end
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      profile = insert(:user)
      conn = get conn, "/profiles/#{profile.id}/music"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
