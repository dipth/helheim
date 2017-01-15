defmodule Altnation.AccountControllerTest do
  use Altnation.ConnCase
  use Bamboo.Test
  alias Altnation.Repo
  alias Altnation.User
  import Altnation.Factory

  describe "new/2" do
    test "it returns a successful response when signed in", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/account/edit"
      assert html_response(conn, 200) =~ gettext("Account Settings")
    end

    test "it redirects when not signed in", %{conn: conn} do
      conn = get conn, "/account/edit"
      assert html_response(conn, 302)
    end
  end

  describe "create/2" do
    test "it allows the update of the users name", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: "New Name", email: user.email, existing_password: "password"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.name == "New Name"
    end

    test "it allows the update of the users e-mail", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: user.name, email: "new@email.com", existing_password: "password"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.email == "new@email.com"
    end

    test "it resets the users confirmation state and sends a confirmation e-mail when changing the e-mail address", %{conn: conn} do
      user = insert(:user)
      existing_confirmation_token = user.confirmation_token
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: user.name, email: "new@email.com", existing_password: "password"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      refute user.confirmed_at
      refute user.confirmation_token == existing_confirmation_token
      assert user.confirmation_token
      assert_delivered_email Altnation.Email.registration_email(user.email, user.confirmation_token)
    end

    test "it does not reset the users confirmation state or send a confirmation e-mail when not changing the e-mail address", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: user.name, email: user.email, existing_password: "password"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.confirmed_at
      assert_no_emails_delivered
    end

    test "it allows the update of the users password", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: user.name, email: user.email, password: "newpassword", password_confirmation: "newpassword", existing_password: "password"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert Altnation.Auth.password_correct?(user.password_hash, "newpassword")
    end

    test "it allows keeping the existing password", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: user.name, email: user.email, password: "", password_confirmation: "", existing_password: "password"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert Altnation.Auth.password_correct?(user.password_hash, "password")
    end

    test "it requires the existing password", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: "New Name", email: "new@email.com", password: "newpassword", password_confirmation: "newpassword", existing_password: ""}, _method: "put")
      assert html_response(conn, 200) =~ gettext("Account Settings")
      user = Repo.get(User, user.id)
      refute user.name == "New Name"
      refute user.email == "new@email.com"
      refute Altnation.Auth.password_correct?(user.password_hash, "newpassword")
    end

    test "it requires that the existing password is correct", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/account", user: %{name: "New Name", email: "new@email.com", password: "newpassword", password_confirmation: "newpassword", existing_password: "wrong"}, _method: "put")
      assert html_response(conn, 200) =~ gettext("Account Settings")
      user = Repo.get(User, user.id)
      refute user.name == "New Name"
      refute user.email == "new@email.com"
      refute Altnation.Auth.password_correct?(user.password_hash, "newpassword")
    end

    test "it requires that the user is signed in", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> post("/account", user: %{name: "New Name", email: "new@email.com", password: "newpassword", password_confirmation: "newpassword", existing_password: "wrong"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      refute user.name == "New Name"
      refute user.email == "new@email.com"
      refute Altnation.Auth.password_correct?(user.password_hash, "newpassword")
    end
  end
end
