defmodule HelheimWeb.PageControllerTest do
  use HelheimWeb.ConnCase

  describe "index/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/"
      assert html_response(conn, 200) =~ gettext("%{site_name} is a community for alternative people.", site_name: gettext("Helheim"))
    end

    test "it redirects to the front_page if you are signed in", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/"
      assert redirected_to(conn) == "/front_page"
    end
  end

  describe "front_page/2" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response without the music section when no listens are tracked", %{conn: conn} do
      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      refute response =~ gettext("Recent listens")
    end

    test "it shows the most recent listens along with the listener", %{conn: conn} do
      listener = insert(:user, username: "melomaniac")
      song = insert(:song, title: "Orion")
      insert(:song_listen, user: listener, song: song)

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      assert response =~ gettext("Recent listens")
      assert response =~ "Orion"
      assert response =~ "melomaniac"
    end

    test "it does not show listens from ignored users", %{conn: conn, user: user} do
      ignoree = insert(:user)
      insert(:ignore, ignorer: user, ignoree: ignoree, enabled: true)
      insert(:song_listen, user: ignoree, song: insert(:song, title: "Orion"))

      conn = get conn, "/front_page"
      refute html_response(conn, 200) =~ gettext("Recent listens")
    end

    test "it does not show the song charts, which live on the music page", %{conn: conn} do
      insert(:song_listen, song: insert(:song, title: "Orion"))
      insert(:song_upvote, song: insert(:song, title: "Blackened"))

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      refute response =~ gettext("Top songs, past 24 hours")
      refute response =~ gettext("Top songs, past 7 days")
      refute response =~ gettext("Most upvoted songs, past 24 hours")
      refute response =~ gettext("Most upvoted songs, past 7 days")
    end

    test "it links to the music page", %{conn: conn} do
      insert(:song_listen, song: insert(:song, title: "Orion"))

      conn = get conn, "/front_page"
      assert html_response(conn, 200) =~ "/music"
    end

    test "it does not show the same song twice in the recent listens", %{conn: conn} do
      user = insert(:user)
      song = insert(:song, title: "Orion")
      insert(:song_listen, user: user, song: song, played_at: Timex.shift(Timex.now, minutes: -10))
      insert(:song_listen, user: user, song: song, played_at: Timex.shift(Timex.now, minutes: -5))

      conn = get conn, "/front_page"
      assert length(String.split(html_response(conn, 200), "Orion")) == 2
    end

    test "it shows at most 15 recent listens", %{conn: conn} do
      insert_list(20, :song_listen)

      conn = get conn, "/front_page"
      assert length(String.split(html_response(conn, 200), "song-cover-frame")) == 16
    end

    test "it only shows the extra listen columns on wider screens", %{conn: conn} do
      insert_list(11, :song_listen)

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      assert response =~ "col-lg-4 hidden-sm-down"
      assert response =~ "col-lg-4 hidden-md-down"
    end

    test "it does not render empty listen columns when there are only a few listens", %{conn: conn} do
      insert_list(3, :song_listen)

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      refute response =~ "col-lg-4 hidden-sm-down"
      refute response =~ "col-lg-4 hidden-md-down"
    end
  end

  describe "confirmation_pending/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/confirmation_pending"
      assert html_response(conn, 200) =~ gettext("Before we can let you in, you need to confirm your e-mail address. Please check your inbox for further instructions...")
    end
  end

  describe "terms/2" do
    test "it returns a successful response with the latest published terms", %{conn: conn} do
      insert(:term, body: "Old Published Terms",   published: true)
      insert(:term, body: "Old Unpublished Terms", published: false)
      insert(:term, body: "New Published Terms",   published: true)
      insert(:term, body: "New Unpublished Terms", published: false)

      conn = get conn, "/terms"
      assert html_response(conn, 200) =~ "New Published Terms"
    end

    test "it returns a successful response when there are no terms", %{conn: conn} do
      conn = get conn, "/terms"
      assert html_response(conn, 200)
    end
  end

  describe "staff/2" do
    test "it returns a successful response when you are logged in", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/staff"
      assert html_response(conn, 200) =~ gettext("Staff Users")
    end

    test "it redirects to the login page if you are not signed in", %{conn: conn} do
      conn = get conn, "/staff"
      assert redirected_to(conn) == "/sessions/new?type=unauthenticated&reason=unauthenticated"
    end
  end
end
