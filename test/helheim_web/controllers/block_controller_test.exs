defmodule HelheimWeb.BlockControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.Block

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/blocks"
      assert html_response(conn, 200)
    end

    test "it only shows users that the current user has blocked", %{conn: conn, user: blocker} do
      user_1 = insert(:user)
      user_2 = insert(:user)
      insert(:block, blocker: blocker, blockee: user_1)
      insert(:block, blockee: user_2)
      conn = get conn, "/blocks"
      assert conn.resp_body =~ user_1.username
      refute conn.resp_body =~ user_2.username
    end

    test "it does not show disabled blocks", %{conn: conn, user: blocker} do
      block = insert(:block, blocker: blocker, enabled: false)
      conn = get conn, "/blocks"
      refute conn.resp_body =~ block.blockee.username
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/blocks"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "returns a successful response when a block from the specified user exists", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      conn = get conn, "/profiles/#{block.blocker.id}/block"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when specifying a non-existing profile id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/1/block"
      end
    end

    test "it redirects to an error page if the specified user does not have an active block against the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user, enabled: false)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{block.blocker.id}/block"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/profiles/1/block"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it blocks the specified user and redirects to the blocks list", %{conn: conn, user: blocker},
      Block, [], [block!: fn(_blocker, _blockee) -> {:ok, nil} end] do

      blockee = Repo.get!(Helheim.User, insert(:user).id)
      conn    = post conn, "/profiles/#{blockee.id}/block"
      assert_called Block.block!(blocker, blockee)
      assert redirected_to(conn) == block_path(conn, :index)
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not block the specified user but redirects to the login page", %{conn: conn},
      Block, [], [block!: fn(_blocker, _blockee) -> raise("block!/2 was called!") end] do

      blockee = insert(:user)
      conn    = post conn, "/profiles/#{blockee.id}/block"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it unblocks the specified user and redirects to the blocks list", %{conn: conn, user: blocker},
      Block, [], [unblock!: fn(_blocker, _blockee) -> {:ok, nil} end] do

      blockee = Repo.get!(Helheim.User, insert(:user).id)
      conn    = delete conn, "/profiles/#{blockee.id}/block"
      assert_called Block.unblock!(blocker, blockee)
      assert redirected_to(conn) == block_path(conn, :index)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not unblock the specified user but redirects to the login page", %{conn: conn},
      Block, [], [unblock!: fn(_blocker, _blockee) -> raise("unblock!/2 was called!") end] do

      blockee = insert(:user)
      conn    = delete conn, "/profiles/#{blockee.id}/block"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
