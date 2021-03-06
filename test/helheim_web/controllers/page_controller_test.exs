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
