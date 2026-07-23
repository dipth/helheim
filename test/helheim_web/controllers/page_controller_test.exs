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

    test "it shows the top songs of the past 24 hours and past 7 days", %{conn: conn} do
      song = insert(:song, title: "Orion")
      insert_list(2, :song_listen, song: song)

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      assert response =~ gettext("Top songs, past 24 hours")
      assert response =~ gettext("Top songs, past 7 days")
    end

    test "it shows the most upvoted songs of the past 24 hours and past 7 days even without recent listens", %{conn: conn} do
      insert(:song_upvote, song: insert(:song, title: "Orion"))

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      assert response =~ gettext("Most upvoted songs, past 24 hours")
      assert response =~ gettext("Most upvoted songs, past 7 days")
      assert response =~ "Orion"
    end

    test "it does not show the same song twice in the recent listens", %{conn: conn} do
      user = insert(:user)
      song = insert(:song, title: "Orion")
      insert(:song_listen, user: user, song: song, played_at: Timex.shift(Timex.now, minutes: -10))
      insert(:song_listen, user: user, song: song, played_at: Timex.shift(Timex.now, minutes: -5))

      conn = get conn, "/front_page"
      response = html_response(conn, 200)
      [_before, after_recent] = String.split(response, gettext("Recent listens"), parts: 2)
      [recent_section, _rest] = String.split(after_recent, gettext("Top songs, past 24 hours"), parts: 2)
      assert length(String.split(recent_section, "Orion")) == 2
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
