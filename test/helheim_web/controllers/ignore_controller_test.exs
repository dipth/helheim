defmodule HelheimWeb.IgnoreControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.Ignore
  alias Helheim.User

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/ignores/new"
      assert html_response(conn, 200)
    end

    test "it assigns a list of users that can be ignored", %{conn: conn, user: _ignorer} do
      user = insert(:user)
      conn = get conn, "/ignores/new"
      assert Enum.member?(conn.assigns[:users], user)
    end

    test "it does not include the current user in the assigned list of users that can be ignored", %{conn: conn, user: ignorer} do
      conn = get conn, "/ignores/new"
      refute Enum.member?(conn.assigns[:users], ignorer)
    end

    test "it does not include the admins in the assigned list of users that can be ignored", %{conn: conn, user: _ignorer} do
      user = insert(:user, role: "admin")
      conn = get conn, "/ignores/new"
      refute Enum.member?(conn.assigns[:users], user)
    end

    test "it does not include the mods in the assigned list of users that can be ignored", %{conn: conn, user: _ignorer} do
      user = insert(:user, role: "mod")
      conn = get conn, "/ignores/new"
      refute Enum.member?(conn.assigns[:users], user)
    end

    test "it does not include unconfirmed users in the assigned list of users that can be ignored", %{conn: conn, user: _ignorer} do
      user = insert(:user, confirmed_at: nil)
      conn = get conn, "/ignores/new"
      refute Enum.member?(conn.assigns[:users], user)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it ignores the specified user and redirects to the blocks and ignores list", %{conn: conn, user: ignorer},
      Ignore, [], [ignore!: fn(_ignorer, _ignoree) -> {:ok, nil} end] do

      ignoree = insert(:user)
      conn    = post conn, "/ignores", ignoree_id: ignoree.id
      assert_called_with_pattern Ignore, :ignore!, fn(args) ->
        ignorer_id = ignorer.id
        ignoree_id = ignoree.id
        [%User{id: ^ignorer_id}, %User{id: ^ignoree_id}] = args
      end
      assert redirected_to(conn) == block_and_ignore_path(conn, :index)
    end

    test_with_mock "it redirects to the block and ignore list and does not ignore the specified user if the user is the current user", %{conn: conn, user: ignorer},
      Ignore, [], [ignore!: fn(_ignorer, _ignoree) -> raise("ignore!/2 was called!") end] do

      conn = post conn, "/ignores", ignoree_id: ignorer.id
      assert redirected_to(conn) =~ block_and_ignore_path(conn, :index)
    end

    test_with_mock "it redirects to the block and ignore list and does not ignore the specified user if the user is an unconfirmed user", %{conn: conn, user: _ignorer},
      Ignore, [], [ignore!: fn(_ignorer, _ignoree) -> raise("ignore!/2 was called!") end] do

      ignoree = insert(:user, confirmed_at: nil)
      conn = post conn, "/ignores", ignoree_id: ignoree.id
      assert redirected_to(conn) =~ block_and_ignore_path(conn, :index)
    end

    test_with_mock "it redirects to the block and ignore list and does not ignore the specified user if the user is an admin", %{conn: conn, user: _ignorer},
      Ignore, [], [ignore!: fn(_ignorer, _ignoree) -> raise("ignore!/2 was called!") end] do

      ignoree = insert(:user, role: "admin")
      conn = post conn, "/ignores", ignoree_id: ignoree.id
      assert redirected_to(conn) =~ block_and_ignore_path(conn, :index)
    end

    test_with_mock "it redirects to the block and ignore list and does not ignore the specified user if the user is a mod", %{conn: conn, user: _ignorer},
      Ignore, [], [ignore!: fn(_ignorer, _ignoree) -> raise("ignore!/2 was called!") end] do

      ignoree = insert(:user, role: "mod")
      conn = post conn, "/ignores", ignoree_id: ignoree.id
      assert redirected_to(conn) =~ block_and_ignore_path(conn, :index)
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not ignore the specified user but redirects to the login page", %{conn: conn},
      Ignore, [], [ignore!: fn(_ignorer, _ignoree) -> raise("ignore!/2 was called!") end] do

      ignoree = insert(:user)
      conn    = post conn, "/ignores", ignoree_id: ignoree.id
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it unignores the specified user and redirects to the blocks and ignores list", %{conn: conn, user: ignorer},
      Ignore, [], [unignore!: fn(_ignorer, _ignoree) -> {:ok, nil} end] do

      ignoree = insert(:user)
      conn    = delete conn, "/ignores/#{ignoree.id}"
      assert_called_with_pattern Ignore, :unignore!, fn(args) ->
        ignorer_id = ignorer.id
        ignoree_id = ignoree.id
        [%User{id: ^ignorer_id}, %User{id: ^ignoree_id}] = args
      end
      assert redirected_to(conn) == block_and_ignore_path(conn, :index)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not unignore the specified user but redirects to the login page", %{conn: conn},
      Ignore, [], [unignore!: fn(_ignorer, _ignoree) -> raise("unignore!/2 was called!") end] do

      ignoree = insert(:user)
      conn    = delete conn, "/ignores/#{ignoree.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
