defmodule Altnation.ConfirmationControllerTest do
  use Altnation.ConnCase
  use Bamboo.Test
  alias Altnation.Repo
  alias Altnation.User
  import Altnation.Factory

  describe "new/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/confirmations/new"
      assert html_response(conn, 200) =~ gettext("Resend confirmation e-mail")
    end
  end

  describe "create/2" do
    test "it sends a registration e-mail and redirects when posting an existing e-mail address", %{conn: conn} do
      user = insert(:user)
      conn = post conn, "/confirmations", confirmation: %{email: user.email}
      assert html_response(conn, 302)
      assert_delivered_email Altnation.Email.registration_email(user.email, user.confirmation_token)
    end

    test "it re-renders the new template when posting a non-existing e-mail address", %{conn: conn} do
      conn = post conn, "/confirmations", confirmation: %{email: "non@existing.com"}
      assert html_response(conn, 200) =~ gettext("No user with that e-mail address!")
      assert_no_emails_delivered
    end
  end

  describe "show/2" do
    test "it confirms a user and redirects when using a valid confirmation token", %{conn: conn} do
      user = insert(:user, confirmed_at: nil)
      assert user.confirmed_at == nil
      conn = get conn, "confirmations/#{user.confirmation_token}"
      user = Repo.get(User, user.id)
      refute user.confirmed_at == nil
      assert html_response(conn, 302)
    end

    test "it redirects when using an invalid confirmation token", %{conn: conn} do
      conn = get conn, "confirmations/someInvalidToken"
      assert html_response(conn, 302)
    end
  end
end
