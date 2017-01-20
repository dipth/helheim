defmodule Altnation.AuthenticationFlowTest do
  use Altnation.AcceptanceCase, async: true
  alias Altnation.Repo
  alias Altnation.User
  import Altnation.Factory

  test "users can sign in and out", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click_link(gettext("Sign In"))
    |> fill_in(gettext("E-mail"), with: user.email)
    |> fill_in(gettext("Password"), with: "password")
    |> click_on(gettext("Sign In"))
    |> find(".alert.alert-info")
    |> text
    assert result == gettext("Welcome back %{username}!", username: user.username)

    result = session
    |> click_link(gettext("Sign Out"))
    |> find(".alert.alert-info")
    |> text
    assert result == gettext("See you later!")
  end

  test "users can remember their password", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click_link(gettext("Sign In"))
    |> fill_in(gettext("E-mail"), with: user.email)
    |> fill_in(gettext("Password"), with: "password")
    |> check(gettext("Remember me"))
    |> click_on(gettext("Sign In"))
    |> find(".alert.alert-info")
    |> text
    assert result == gettext("Welcome back %{username}!", username: user.username)

    session
    |> execute_script("$.removeCookie('_altnation_key', { path: '/' });")
    |> visit("/")

    assert get_current_path(session) == "front_page"

    result = session
    |> click_link(gettext("Sign Out"))
    |> find(".alert.alert-info")
    |> text
    assert result == gettext("See you later!")

    session
    |> execute_script("$.removeCookie('_altnation_key', { path: '/' });")
    |> visit("/")

    assert get_current_path(session) == ""
  end
end
