defmodule HelheimWeb.SongControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.Deezer

  ##############################################################################
  # recent/2
  describe "recent/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the most recent listens with the listener", %{conn: conn} do
      listener = insert(:user, username: "melomaniac")
      insert(:song_listen, user: listener, song: insert(:song, title: "Creeping Death"))

      conn = get conn, "/songs/recent"
      response = html_response(conn, 200)
      assert response =~ "Creeping Death"
      assert response =~ "melomaniac"
    end

    test "it only shows the most recent listen of a song played on repeat", %{conn: conn} do
      user = insert(:user)
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, user: user, song: song, played_at: Timex.shift(Timex.now, minutes: -10))
      insert(:song_listen, user: user, song: song, played_at: Timex.shift(Timex.now, minutes: -5))

      conn = get conn, "/songs/recent"
      response = html_response(conn, 200)
      assert length(String.split(response, "Creeping Death")) == 2
    end

    test "it does not show listens from ignored users", %{conn: conn, user: user} do
      ignoree = insert(:user)
      insert(:ignore, ignorer: user, ignoree: ignoree, enabled: true)
      insert(:song_listen, user: ignoree, song: insert(:song, title: "Creeping Death"))

      conn = get conn, "/songs/recent"
      refute html_response(conn, 200) =~ "Creeping Death"
    end

    test "it clamps the page number to the pagination cap", %{conn: conn} do
      insert(:song_listen)
      conn = get conn, "/songs/recent", %{"page" => "999"}
      assert html_response(conn, 200)
    end

    test "it renders a placeholder when a song has no cover art", %{conn: conn} do
      song = insert(:song, cover_image_url_small: nil)
      insert(:song_listen, song: song)

      conn = get conn, "/songs/recent"
      assert html_response(conn, 200) =~ "song-cover-placeholder"
    end
  end

  describe "recent/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/songs/recent"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # top_day/2 + top_week/2
  describe "top_day/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows songs listened to within the past 24 hours", %{conn: conn} do
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, hours: -23))

      conn = get conn, "/songs/top/day"
      assert html_response(conn, 200) =~ "Creeping Death"
    end

    test "it does not include songs only listened to more than 24 hours ago", %{conn: conn} do
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, hours: -25))

      conn = get conn, "/songs/top/day"
      refute html_response(conn, 200) =~ "Creeping Death"
    end
  end

  describe "top_week/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows songs listened to within the past 7 days", %{conn: conn} do
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, days: -6))

      conn = get conn, "/songs/top/week"
      assert html_response(conn, 200) =~ "Creeping Death"
    end

    test "it does not include songs only listened to more than 7 days ago", %{conn: conn} do
      song = insert(:song, title: "Creeping Death")
      insert(:song_listen, song: song, played_at: Timex.shift(Timex.now, days: -8))

      conn = get conn, "/songs/top/week"
      refute html_response(conn, 200) =~ "Creeping Death"
    end
  end

  describe "top_day/2 and top_week/2 when not signed in" do
    test "they redirect to the sign in page", %{conn: conn} do
      assert redirected_to(get(conn, "/songs/top/day")) =~ session_path(conn, :new)
      assert redirected_to(get(build_conn(), "/songs/top/week")) =~ session_path(conn, :new)
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

    test "it does not show listeners who block the current user", %{conn: conn, user: user} do
      song = insert(:song)
      blocker = insert(:user, username: "blocky-mc-blockface")
      insert(:block, blocker: blocker, blockee: user)
      insert(:song_listen, song: song, user: blocker)

      conn = get conn, "/songs/#{song.id}"
      refute html_response(conn, 200) =~ "blocky-mc-blockface"
    end

    test "it does not show listeners that the current user ignores", %{conn: conn, user: user} do
      song = insert(:song)
      ignoree = insert(:user, username: "ignored-individual")
      insert(:ignore, ignorer: user, ignoree: ignoree, enabled: true)
      insert(:song_listen, song: song, user: ignoree)

      conn = get conn, "/songs/#{song.id}"
      refute html_response(conn, 200) =~ "ignored-individual"
    end

    test "it shows the enriched metadata when present", %{conn: conn} do
      song = insert(:song,
        release_year: 1986,
        cover_image_url: "https://lastfm.freetls.fastly.net/i/u/300x300/abc.jpg",
        cover_image_url_large: "https://lastfm.freetls.fastly.net/i/u/500x500/abc.jpg")
      tag = insert(:tag, name: "thrash metal")
      Repo.insert!(%Helheim.SongTag{song_id: song.id, tag_id: tag.id, position: 1})

      conn = get conn, "/songs/#{song.id}"
      response = html_response(conn, 200)
      assert response =~ "1986"
      assert response =~ "thrash metal"
      assert response =~ "500x500"
    end

    test "it shows a preview button when the song has a deezer id", %{conn: conn} do
      song = insert(:song, deezer_id: 424_565_222)

      conn = get conn, "/songs/#{song.id}"
      response = html_response(conn, 200)
      assert response =~ "song-preview-button"
      assert response =~ "/songs/#{song.id}/preview"
    end

    test "it does not show a preview button when the song has no deezer id", %{conn: conn} do
      song = insert(:song, deezer_id: nil)

      conn = get conn, "/songs/#{song.id}"
      refute html_response(conn, 200) =~ "song-preview-button"
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
  # preview/2
  describe "preview/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it redirects to a freshly resolved deezer preview url", %{conn: conn} do
      song = insert(:song, deezer_id: 424_565_222)

      with_mock Deezer.Client, [:passthrough], [
        track_preview_url: fn 424_565_222 -> {:ok, "https://cdnt-preview.dzcdn.net/api/1/1/abc.mp3?hdnea=exp=123"} end
      ] do
        conn = get conn, "/songs/#{song.id}/preview"
        assert redirected_to(conn) == "https://cdnt-preview.dzcdn.net/api/1/1/abc.mp3?hdnea=exp=123"
      end
    end

    test "it returns a 404 when the song has no deezer id", %{conn: conn} do
      song = insert(:song, deezer_id: nil)

      conn = get conn, "/songs/#{song.id}/preview"
      assert response(conn, 404)
    end

    test "it returns a 404 when deezer cannot resolve the preview", %{conn: conn} do
      song = insert(:song, deezer_id: 424_565_222)

      with_mock Deezer.Client, [:passthrough], [track_preview_url: fn _id -> {:error, :not_found} end] do
        conn = get conn, "/songs/#{song.id}/preview"
        assert response(conn, 404)
      end
    end

    test "it returns a 404 when the song does not exist", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/songs/1234567/preview"
      end
    end
  end

  describe "preview/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      song = insert(:song, deezer_id: 424_565_222)
      conn = get conn, "/songs/#{song.id}/preview"
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

  ##############################################################################
  # top_upvoted_day/2 and top_upvoted_week/2
  describe "top_upvoted_day/2 and top_upvoted_week/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it shows the most upvoted songs of the past 24 hours", %{conn: conn} do
      insert(:song_upvote, song: insert(:song, title: "Creeping Death"))

      response = conn |> get("/songs/top/upvoted/day") |> html_response(200)
      assert response =~ "Creeping Death"
      assert response =~ gettext("Most upvoted songs, past 24 hours")
    end

    test "it shows the most upvoted songs of the past 7 days", %{conn: conn} do
      insert(:song_upvote, song: insert(:song, title: "Creeping Death"))

      response = conn |> get("/songs/top/upvoted/week") |> html_response(200)
      assert response =~ "Creeping Death"
      assert response =~ gettext("Most upvoted songs, past 7 days")
    end

    test "it does not count upvotes from ignored users", %{conn: conn, user: user} do
      ignoree = insert(:user)
      insert(:ignore, ignorer: user, ignoree: ignoree, enabled: true)
      insert(:song_upvote, user: ignoree, song: insert(:song, title: "Creeping Death"))

      response = conn |> get("/songs/top/upvoted/day") |> html_response(200)
      refute response =~ "Creeping Death"
    end
  end

  describe "top_upvoted_day/2 and top_upvoted_week/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      assert conn |> get("/songs/top/upvoted/day") |> redirected_to() =~ session_path(conn, :new)
      assert conn |> get("/songs/top/upvoted/week") |> redirected_to() =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # upvote/2
  describe "upvote/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it upvotes the song and increments its counter", %{conn: conn, user: user} do
      song = insert(:song, upvotes_count: 0)

      conn = post conn, "/songs/#{song.id}/upvote"

      assert redirected_to(conn) == song_path(conn, :show, song)
      assert Repo.get(Helheim.Song, song.id).upvotes_count == 1
      assert Repo.exists?(from u in Helheim.SongUpvote, where: u.user_id == ^user.id and u.song_id == ^song.id)
    end

    test "it returns a 404 when the song does not exist", %{conn: conn} do
      assert_error_sent :not_found, fn -> post conn, "/songs/1234567/upvote" end
    end

    test "it returns the resulting state as JSON for async requests", %{conn: conn} do
      song = insert(:song, upvotes_count: 0)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post("/songs/#{song.id}/upvote")

      assert json_response(conn, 200) == %{"upvoted" => true, "upvotes_count" => 1}
    end

    test "it returns the current state as JSON when the song was already upvoted", %{conn: conn, user: user} do
      song = insert(:song, upvotes_count: 1)
      insert(:song_upvote, user: user, song: song)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post("/songs/#{song.id}/upvote")

      assert json_response(conn, 200) == %{"upvoted" => true, "upvotes_count" => 1}
    end
  end

  describe "upvote/2 when not signed in" do
    test "it redirects to the sign in page and does not upvote", %{conn: conn} do
      song = insert(:song, upvotes_count: 0)
      conn = post conn, "/songs/#{song.id}/upvote"
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert Repo.get(Helheim.Song, song.id).upvotes_count == 0
    end
  end

  ##############################################################################
  # remove_upvote/2
  describe "remove_upvote/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it removes the current user's upvote and decrements the counter", %{conn: conn, user: user} do
      song = insert(:song, upvotes_count: 1)
      insert(:song_upvote, user: user, song: song)

      conn = delete conn, "/songs/#{song.id}/upvote"

      assert redirected_to(conn) == song_path(conn, :show, song)
      refute Repo.exists?(from u in Helheim.SongUpvote, where: u.user_id == ^user.id and u.song_id == ^song.id)
      assert Repo.get(Helheim.Song, song.id).upvotes_count == 0
    end

    test "it returns the resulting state as JSON for async requests", %{conn: conn, user: user} do
      song = insert(:song, upvotes_count: 1)
      insert(:song_upvote, user: user, song: song)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> delete("/songs/#{song.id}/upvote")

      assert json_response(conn, 200) == %{"upvoted" => false, "upvotes_count" => 0}
    end
  end

  describe "remove_upvote/2 when not signed in" do
    test "it redirects to the sign in page and does not remove any upvotes", %{conn: conn} do
      upvote = insert(:song_upvote)
      conn = delete conn, "/songs/#{upvote.song_id}/upvote"
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert Repo.get(Helheim.SongUpvote, upvote.id)
    end
  end
end
