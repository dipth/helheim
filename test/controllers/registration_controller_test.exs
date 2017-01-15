defmodule Altnation.RegistrationControllerTest do
  use Altnation.ConnCase
  use Bamboo.Test
  alias Altnation.Repo
  alias Altnation.User

  describe "new/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/registrations/new"
      assert html_response(conn, 200) =~ gettext("New Registration")
    end
  end

  describe "create/2" do
    @valid_params %{name: "Foo Bar", username: "foobar", email: "foo@bar.dk", password: "password"}
    @invalid_params %{email: "foo@bar.dk"}

    test "it creates a user, sends a registration e-mail and redirects when posting valid params", %{conn: conn} do
      conn = post conn, "/registrations", user: @valid_params
      assert html_response(conn, 302)
      user = Repo.get_by(User, email: @valid_params[:email])
      assert user
      assert_delivered_email Altnation.Email.registration_email(user)
    end

    test "it does not create a user but re-renders the new template when posting invalid params", %{conn: conn} do
      conn = post conn, "/registrations", user: @invalid_params
      assert html_response(conn, 200) =~ gettext("New Registration")
      refute Repo.get_by(User, email: @valid_params[:email])
    end
  end
end
