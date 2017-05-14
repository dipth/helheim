defmodule Helheim.UsernameControllerTest do
  use Helheim.ConnCase

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "returns a successful response containing all usernames", %{conn: conn, user: user1} do
      user2 = insert(:user, username: "zzz")
      conn = get conn, "/usernames"
      assert json_response(conn, 200) == [user1.username, user2.username]
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the login page", %{conn: conn} do
      conn = get conn, "/usernames"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "redirects to the specified users public profile page", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/usernames/#{user.username}"
      assert redirected_to(conn) == public_profile_path(conn, :show, user)
    end

    test "returns an error when there is no user with the specified username", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/usernames/foo"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the login page when specifying an existing username", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/usernames/#{user.username}"
      assert redirected_to(conn) == session_path(conn, :new)
    end

    test "it redirects to the login page when specifying a non-existing username", %{conn: conn} do
      conn = get conn, "/usernames/foo"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
