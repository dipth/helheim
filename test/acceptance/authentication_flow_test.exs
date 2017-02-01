defmodule Helheim.AuthenticationFlowTest do
  use Helheim.AcceptanceCase#, async: true

  test "users can sign in and out", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click_link(gettext("Sign In"))
    |> fill_in(gettext("E-mail"), with: user.email)
    |> fill_in(gettext("Password"), with: "password")
    |> click_on(gettext("Sign In"))
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("Welcome back %{username}!", username: user.username)

    session
    |> find(".nav-item-user-menu")
    |> click_link(user.username)
    |> click_link(gettext("Sign Out"))

    result = session
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("See you later!")
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
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("Welcome back %{username}!", username: user.username)

    session
    |> execute_script("document.cookie = '_helheim_key=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';")

    session
    |> visit("/")
    assert get_current_path(session) == "/front_page"

    session
    |> find(".nav-item-user-menu")
    |> click_link(user.username)
    |> click_link(gettext("Sign Out"))

    result = session
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("See you later!")

    session
    |> visit("/")

    assert get_current_path(session) == "/"
  end
end
