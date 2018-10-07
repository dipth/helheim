defmodule HelheimWeb.Admin.User.VerificationControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.User

  ##############################################################################
  # create/2
  describe "create/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test_with_mock "it verifies the user and redirects to the admin page for the user", %{conn: conn, admin: admin},
      User, [:passthrough], [verify!: fn(user, _admin) -> {:ok, user} end] do

      user = insert(:user)
      conn = post conn, "/admin/users/#{user.id}/verification"

      assert redirected_to(conn) == admin_user_path(conn, :show, user)
      assert called User.verify!(user, admin)
    end

    test_with_mock "it redirects back to the admin page for the user when the verification fails", %{conn: conn},
      User, [:passthrough], [verify!: fn(_user, _admin) -> {:error, "failed"} end] do

      user = insert(:user)
      conn = post conn, "/admin/users/#{user.id}/verification"
      assert redirected_to(conn) == admin_user_path(conn, :show, user)
    end
  end

  describe "create/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test_with_mock "it does not verify the user but shows a 401 error", %{conn: conn},
      User, [:passthrough], [verify!: fn(_user, _admin) -> raise "verify! called" end] do

      user = insert(:user)
      assert_error_sent 403, fn ->
        post conn, "/admin/users/#{user.id}/verification"
      end
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not verify the user but redirects to the sign in page", %{conn: conn},
      User, [:passthrough], [verify!: fn(_user, _admin) -> raise "verify! called" end] do

      user = insert(:user)
      conn = post conn, "/admin/users/#{user.id}/verification"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test_with_mock "it unverifies the user and redirects to the admin page for the user", %{conn: conn},
      User, [:passthrough], [unverify!: fn(user) -> {:ok, user} end] do

      user = insert(:user)
      conn = delete conn, "/admin/users/#{user.id}/verification"

      assert redirected_to(conn) == admin_user_path(conn, :show, user)
      assert called User.unverify!(user)
    end

    test_with_mock "it redirects back to the admin page for the user when the unverification fails", %{conn: conn},
      User, [:passthrough], [unverify!: fn(_user) -> {:error, "failed"} end] do

      user = insert(:user)
      conn = delete conn, "/admin/users/#{user.id}/verification"
      assert redirected_to(conn) == admin_user_path(conn, :show, user)
    end
  end

  describe "delete/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test_with_mock "it does not unverify the user but shows a 401 error", %{conn: conn},
      User, [:passthrough], [unverify!: fn(_user) -> raise "unverify! called" end] do

      user = insert(:user)
      assert_error_sent 403, fn ->
        delete conn, "/admin/users/#{user.id}/verification"
      end
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not unverify the user but redirects to the sign in page", %{conn: conn},
      User, [:passthrough], [unverify!: fn(_user) -> raise "unverify! called" end] do

      user = insert(:user)
      conn = delete conn, "/admin/users/#{user.id}/verification"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
