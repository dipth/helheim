defmodule Altnation.AuthenticationFlowTest do
  use Altnation.AcceptanceCase, async: true
  alias Altnation.Repo
  alias Altnation.User
  import Altnation.Factory

  test "users can sign in and out", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click_link("Sign in")
    |> fill_in("E-mail", with: user.email)
    |> fill_in("Password", with: "password")
    |> click_on("Sign In")
    |> find(".alert.alert-info")
    |> text
    assert result == "Welcome back #{user.username}!"

    result = session
    |> click_link("Sign out")
    |> find(".alert.alert-info")
    |> text
    assert result == "See you later!"
  end
end
