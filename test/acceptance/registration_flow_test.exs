defmodule Helheim.RegistrationFlowTest do
  use Helheim.AcceptanceCase, async: true
  alias Helheim.Repo
  alias Helheim.User

  defp success_alert, do: Query.css(".alert.alert-success")

  test "users can register", %{session: session} do
    result = session
    |> visit("/")
    |> click(Query.link(gettext("Register Account")))
    |> fill_in(Query.text_field(gettext("Name")), with: "Foo Bar")
    |> fill_in(Query.text_field(gettext("Username")), with: "foobar")
    |> fill_in(Query.text_field(gettext("E-mail")), with: "foo@bar.dk")
    |> fill_in(Query.text_field(gettext("Password")), with: "password")
    |> fill_in(Query.text_field(gettext("Confirm Password")), with: "password")
    |> click(Query.button(gettext("Create Account")))
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("User created!")

    # TODO: Check that the user cannot sign in before confirming

    user = Repo.get_by(User, email: "foo@bar.dk")
    result = session
    |> visit("/confirmations/#{user.confirmation_token}")
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("User confirmed!")
  end
end
