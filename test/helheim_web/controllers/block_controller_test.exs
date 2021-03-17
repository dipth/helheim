defmodule HelheimWeb.BlockControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.Block
  alias Helheim.User

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
      conn = get conn, "/blocks/#{block.blocker.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when specifying a non-existing profile id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/blocks/1"
      end
    end

    test "it redirects to an error page if the specified user does not have an active block against the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user, enabled: false)
      assert_error_sent :not_found, fn ->
        get conn, "/blocks/#{block.blocker.id}"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/blocks/1"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/blocks/new"
      assert html_response(conn, 200)
    end

    test "it assigns a list of users that can be blocked", %{conn: conn, user: _blocker} do
      user = insert(:user)
      conn = get conn, "/blocks/new"
      assert Enum.member?(conn.assigns[:users], user)
    end

    test "it does not include the current user in the assigned list of users that can be blocked", %{conn: conn, user: blocker} do
      conn = get conn, "/blocks/new"
      refute Enum.member?(conn.assigns[:users], blocker)
    end

    test "it does not include the admins in the assigned list of users that can be blocked", %{conn: conn, user: _blocker} do
      user = insert(:user, role: "admin")
      conn = get conn, "/blocks/new"
      refute Enum.member?(conn.assigns[:users], user)
    end

    test "it does not include the mods in the assigned list of users that can be blocked", %{conn: conn, user: _blocker} do
      user = insert(:user, role: "mod")
      conn = get conn, "/blocks/new"
      refute Enum.member?(conn.assigns[:users], user)
    end

    test "it does not include unconfirmed users in the assigned list of users that can be blocked", %{conn: conn, user: _blocker} do
      user = insert(:user, confirmed_at: nil)
      conn = get conn, "/blocks/new"
      refute Enum.member?(conn.assigns[:users], user)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it blocks the specified user and redirects to the blocks list", %{conn: conn, user: blocker},
      Block, [], [block!: fn(_blocker, _blockee) -> {:ok, nil} end] do

      blockee = insert(:user)
      conn    = post conn, "/blocks", blockee_id: blockee.id
      assert_called_with_pattern Block, :block!, fn(args) ->
        blocker_id = blocker.id
        blockee_id = blockee.id
        [%User{id: ^blocker_id}, %User{id: ^blockee_id}] = args
      end
      assert redirected_to(conn) == block_path(conn, :index)
    end

    test_with_mock "it redirects to the block list and does not block the specified user if the user is the current user", %{conn: conn, user: blocker},
      Block, [], [block!: fn(_blocker, _blockee) -> raise("block!/2 was called!") end] do

      conn = post conn, "/blocks", blockee_id: blocker.id
      assert redirected_to(conn) =~ block_path(conn, :index)
    end

    test_with_mock "it redirects to the block list and does not block the specified user if the user is an unconfirmed user", %{conn: conn, user: _blocker},
      Block, [], [block!: fn(_blocker, _blockee) -> raise("block!/2 was called!") end] do

      blockee = insert(:user, confirmed_at: nil)
      conn = post conn, "/blocks", blockee_id: blockee.id
      assert redirected_to(conn) =~ block_path(conn, :index)
    end

    test_with_mock "it redirects to the block list and does not block the specified user if the user is an admin", %{conn: conn, user: _blocker},
      Block, [], [block!: fn(_blocker, _blockee) -> raise("block!/2 was called!") end] do

      blockee = insert(:user, role: "admin")
      conn = post conn, "/blocks", blockee_id: blockee.id
      assert redirected_to(conn) =~ block_path(conn, :index)
    end

    test_with_mock "it redirects to the block list and does not block the specified user if the user is a mod", %{conn: conn, user: _blocker},
      Block, [], [block!: fn(_blocker, _blockee) -> raise("block!/2 was called!") end] do

      blockee = insert(:user, role: "mod")
      conn = post conn, "/blocks", blockee_id: blockee.id
      assert redirected_to(conn) =~ block_path(conn, :index)
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not block the specified user but redirects to the login page", %{conn: conn},
      Block, [], [block!: fn(_blocker, _blockee) -> raise("block!/2 was called!") end] do

      blockee = insert(:user)
      conn    = post conn, "/blocks", blockee_id: blockee.id
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it unblocks the specified user and redirects to the blocks list", %{conn: conn, user: blocker},
      Block, [], [unblock!: fn(_blocker, _blockee) -> {:ok, nil} end] do

      blockee = insert(:user)
      conn    = delete conn, "/blocks/#{blockee.id}"
      assert_called_with_pattern Block, :unblock!, fn(args) ->
        blocker_id = blocker.id
        blockee_id = blockee.id
        [%User{id: ^blocker_id}, %User{id: ^blockee_id}] = args
      end
      assert redirected_to(conn) == block_path(conn, :index)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not unblock the specified user but redirects to the login page", %{conn: conn},
      Block, [], [unblock!: fn(_blocker, _blockee) -> raise("unblock!/2 was called!") end] do

      blockee = insert(:user)
      conn    = delete conn, "/blocks/#{blockee.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
