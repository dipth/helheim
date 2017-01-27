defmodule Helheim.PasswordResetControllerTest do
  use Helheim.ConnCase
  use Bamboo.Test
  alias Helheim.Repo
  alias Helheim.User

  describe "new/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/password_resets/new"
      assert html_response(conn, 200) =~ gettext("Forgot your password?")
    end
  end

  describe "create/2" do
    test "it updates the password reset token of the user, sends a password reset e-mail and redirects when posting an existing e-mail address", %{conn: conn} do
      user = insert(:user, password_reset_token: nil, password_reset_token_updated_at: nil)
      conn = post conn, "/password_resets", password_reset: %{email: user.email}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.password_reset_token
      {:ok, time_diff, _, _} = Calendar.DateTime.diff(user.password_reset_token_updated_at, DateTime.utc_now)
      assert time_diff < 10
      assert_delivered_email Helheim.Email.password_reset_email(user)
    end

    test "it re-renders the new template when posting a non-confirmed e-mail address", %{conn: conn} do
      user = insert(:user, confirmed_at: nil)
      conn = post conn, "/password_resets", password_reset: %{email: user.email}
      assert html_response(conn, 200) =~ gettext("You need to confirm your e-mail address before you can reset your password")
      user = Repo.get(User, user.id)
      refute user.password_reset_token
    end

    test "it re-renders the new template when posting a non-existing e-mail address", %{conn: conn} do
      conn = post conn, "/password_resets", password_reset: %{email: "non@existing.com"}
      assert html_response(conn, 200) =~ gettext("No user with that e-mail address!")
    end
  end

  describe "show/2" do
    test "it returns a successful response if the reset token is valid and not expired", %{conn: conn} do
      insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: DateTime.utc_now)
      conn = get conn, "/password_resets/sometoken"
      assert html_response(conn, 200) =~ gettext("Change Password")
    end

    test "it redirects the user if the reset token is valid but expired", %{conn: conn} do
      updated_at = Calendar.DateTime.subtract!(DateTime.utc_now, 24 * 60 * 60)
      insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: updated_at)
      conn = get conn, "/password_resets/sometoken"
      assert html_response(conn, 302)
    end

    test "it redirects the user if the reset token is invalid", %{conn: conn} do
      insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: DateTime.utc_now)
      conn = get conn, "/password_resets/someothertoken"
      assert html_response(conn, 302)
    end
  end

  describe "update/2" do
    test "it changes the users password, clears his reset token, signs him in and redirects him when posting a valid password", %{conn: conn} do
      user = insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: DateTime.utc_now)
      old_password_hash = user.password_hash
      conn = post conn, "/password_resets/sometoken", user: %{password: "myshinynewpassword", password_confirmation: "myshinynewpassword"}, _method: "patch"
      assert html_response(conn, 302)
      assert Guardian.Plug.current_resource(conn).id == user.id
      user = Repo.get(User, user.id)
      refute user.password_hash == old_password_hash
      refute user.password_reset_token
    end

    test "it does not change the users password, clear his reset token or sign him in, but re-renders the new template when posting an invalid password", %{conn: conn} do
      user = insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: DateTime.utc_now)
      old_password_hash = user.password_hash
      conn = post conn, "/password_resets/sometoken", user: %{password: ""}, _method: "patch"
      assert html_response(conn, 200) =~ gettext("Change Password")
      refute Guardian.Plug.current_resource(conn)
      user = Repo.get(User, user.id)
      assert user.password_hash == old_password_hash
      assert user.password_reset_token == "sometoken"
    end

    test "it does not change the users password or sign him in, but redirects when the reset token is invalid", %{conn: conn} do
      user = insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: DateTime.utc_now)
      old_password_hash = user.password_hash
      conn = post conn, "/password_resets/someothertoken", user: %{password: "myshinynewpassword", password_confirmation: "myshinynewpassword"}, _method: "patch"
      assert html_response(conn, 302)
      refute Guardian.Plug.current_resource(conn)
      user = Repo.get(User, user.id)
      assert user.password_hash == old_password_hash
      assert user.password_reset_token == "sometoken"
    end

    test "it does not change the users password or sign him in, but redirects when the reset token is expired", %{conn: conn} do
      updated_at = Calendar.DateTime.subtract!(DateTime.utc_now, 24 * 60 * 60)
      user = insert(:user, password_reset_token: "sometoken", password_reset_token_updated_at: updated_at)
      old_password_hash = user.password_hash
      conn = post conn, "/password_resets/someothertoken", user: %{password: "myshinynewpassword", password_confirmation: "myshinynewpassword"}, _method: "patch"
      assert html_response(conn, 302)
      refute Guardian.Plug.current_resource(conn)
      user = Repo.get(User, user.id)
      assert user.password_hash == old_password_hash
      assert user.password_reset_token == "sometoken"
    end
  end
end
