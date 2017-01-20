defmodule Altnation.PageControllerTest do
  use Altnation.ConnCase
  import Altnation.Factory

  describe "index/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/"
      assert html_response(conn, 200) =~ gettext("%{site_name} is a community for alternative people.", site_name: gettext("Altnation"))
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

  describe "signed_in/2" do
    test "it redirects when not signed in", %{conn: conn} do
      conn = get conn, "/signed_in"
      assert html_response(conn, 302)
    end

    test "it returns a successful response when signed in", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/signed_in"
      assert html_response(conn, 200) =~ gettext("You are now signed in")
    end
  end
end
