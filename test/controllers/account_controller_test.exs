defmodule Helheim.AccountControllerTest do
  use Helheim.ConnCase
  import Mock
  use Bamboo.Test
  alias Helheim.Repo
  alias Helheim.User

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when signed in", %{conn: conn} do
      conn = get conn, "/account/edit"
      assert html_response(conn, 200) =~ gettext("Account Settings")
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/account/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it allows the update of the users name", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: "New Name", email: user.email, existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.name == "New Name"
    end

    test "it allows the update of the users e-mail", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: user.name, email: "new@email.com", existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.email == "new@email.com"
    end

    test "it resets the users confirmation state and sends a confirmation e-mail when changing the e-mail address", %{conn: conn, user: user} do
      existing_confirmation_token = user.confirmation_token
      conn = put conn, "/account", user: %{name: user.name, email: "new@email.com", existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      refute user.confirmed_at
      refute user.confirmation_token == existing_confirmation_token
      assert user.confirmation_token
      assert_delivered_email Helheim.Email.registration_email(user.email, user.confirmation_token)
    end

    test "it does not reset the users confirmation state or send a confirmation e-mail when not changing the e-mail address", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: user.name, email: user.email, existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.confirmed_at
      assert_no_emails_delivered()
    end

    test "it allows the update of the users password", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: user.name, email: user.email, password: "newpassword", password_confirmation: "newpassword", existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert Helheim.Auth.password_correct?(user.password_hash, "newpassword")
    end

    test "it allows keeping the existing password", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: user.name, email: user.email, password: "", password_confirmation: "", existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert Helheim.Auth.password_correct?(user.password_hash, "password")
    end

    test "it requires the existing password", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: "New Name", email: "new@email.com", password: "newpassword", password_confirmation: "newpassword", existing_password: ""}
      assert html_response(conn, 200) =~ gettext("Account Settings")
      user = Repo.get(User, user.id)
      refute user.name == "New Name"
      refute user.email == "new@email.com"
      refute Helheim.Auth.password_correct?(user.password_hash, "newpassword")
    end

    test "it requires that the existing password is correct", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: "New Name", email: "new@email.com", password: "newpassword", password_confirmation: "newpassword", existing_password: "wrong"}
      assert html_response(conn, 200) =~ gettext("Account Settings")
      user = Repo.get(User, user.id)
      refute user.name == "New Name"
      refute user.email == "new@email.com"
      refute Helheim.Auth.password_correct?(user.password_hash, "newpassword")
    end

    test "it trims whitespace", %{conn: conn, user: user} do
      conn = put conn, "/account", user: %{name: "   New Name   ", email: "   new@email.com   ", existing_password: "password"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.name == "New Name"
      assert user.email == "new@email.com"
    end
  end

  describe "update/2 when not signed in" do
    test "it redirects back to the sign in page", %{conn: conn} do
      conn = put conn, "/account", user: %{name: "New Name", email: "new@email.com", password: "newpassword", password_confirmation: "newpassword", existing_password: "wrong"}
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it deletes the users account, signs him out and redirects to the landing page", %{conn: conn, user: user},
      User, [:passthrough], [delete!: fn(_user) -> {:ok} end] do

      conn = delete conn, "/account"
      assert called User.delete!(user)
      assert redirected_to(conn) == page_path(conn, :index)
      refute Guardian.Plug.current_resource(conn)
    end
  end

  describe "delete/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = delete conn, "/account"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
