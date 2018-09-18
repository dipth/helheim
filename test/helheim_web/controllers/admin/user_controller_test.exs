defmodule HelheimWeb.Admin.UserControllerTest do
  use HelheimWeb.ConnCase

  ##############################################################################
  # index/2
  describe "index/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/admin/users"
      assert html_response(conn, 200) =~ gettext("Users")
    end
  end

  describe "index/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        get conn, "/admin/users"
      end
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/admin/users"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn, admin: admin} do
      conn = get conn, "/admin/users/#{admin.id}"
      assert html_response(conn, 200) =~ admin.username
    end
  end

  describe "show/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn, user: user} do
      assert_error_sent 403, fn ->
        get conn, "/admin/users/#{user.id}"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/admin/users/#{user.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
