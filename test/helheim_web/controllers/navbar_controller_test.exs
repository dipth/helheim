defmodule HelheimWeb.NavbarControllerTest do
  use HelheimWeb.ConnCase

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/navbar"
      assert html_response(conn, 200)
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/navbar"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
