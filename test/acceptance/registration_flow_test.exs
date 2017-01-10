defmodule Altnation.RegistrationFlowTest do
  use Altnation.AcceptanceCase, async: true
  alias Altnation.Repo
  alias Altnation.User

  test "users can register", %{session: session} do
    result = session
    |> visit("/")
    |> click_link(gettext("Register Account"))
    |> fill_in(gettext("Name"), with: "Foo Bar")
    |> fill_in(gettext("Username"), with: "foobar")
    |> fill_in(gettext("E-mail"), with: "foo@bar.dk")
    |> fill_in(gettext("Password"), with: "password")
    |> click_on(gettext("Create Account"))
    |> find(".alert.alert-info")
    |> text
    assert result == gettext("User created!")

    # TODO: Check that the user cannot sign in before confirming

    user = Repo.get_by(User, email: "foo@bar.dk")
    result = session
    |> visit("/confirmations/#{user.confirmation_token}")
    |> find(".alert.alert-info")
    |> text
    assert result == gettext("User confirmed!")
  end
end
