defmodule HelheimWeb.BlockAndIgnoreControllerTest do
  use HelheimWeb.ConnCase

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/blocks_and_ignores"
      assert html_response(conn, 200)
    end

    test "it shows users that the current user has blocked", %{conn: conn, user: blocker} do
      block = insert(:block, blocker: blocker)
      conn  = get conn, "/blocks_and_ignores"
      assert conn.resp_body =~ block.blockee.username
    end

    test "it does not show users that the current user has not blocked", %{conn: conn, user: _blocker} do
      user = insert(:user)
      conn = get conn, "/blocks_and_ignores"
      refute conn.resp_body =~ user.username
    end

    test "it does not show disabled blocks", %{conn: conn, user: blocker} do
      block = insert(:block, blocker: blocker, enabled: false)
      conn  = get conn, "/blocks_and_ignores"
      refute conn.resp_body =~ block.blockee.username
    end

    test "it shows users that the current user has ignored", %{conn: conn, user: ignorer} do
      ignore = insert(:ignore, ignorer: ignorer)
      conn   = get conn, "/blocks_and_ignores"
      assert conn.resp_body =~ ignore.ignoree.username
    end

    test "it does not show users that the current user has not ignored", %{conn: conn, user: _ignorer} do
      user = insert(:user)
      conn = get conn, "/blocks_and_ignores"
      refute conn.resp_body =~ user.username
    end

    test "it does not show disabled ignores", %{conn: conn, user: ignorer} do
      ignore = insert(:ignore, ignorer: ignorer, enabled: false)
      conn   = get conn, "/blocks_and_ignores"
      refute conn.resp_body =~ ignore.ignoree.username
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/blocks_and_ignores"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
