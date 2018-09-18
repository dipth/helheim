defmodule HelheimWeb.AuthenticationFlowTest do
  use HelheimWeb.AcceptanceCase#, async: true

  defp sign_in_link,    do: Query.link(gettext("Sign In"))
  defp email_field,     do: Query.text_field(gettext("E-mail"))
  defp password_field,  do: Query.text_field(gettext("Password"))
  defp sign_in_button,  do: Query.button(gettext("Sign In"))
  defp success_alert,   do: Query.css(".alert.alert-success")
  defp user_menu,       do: Query.css(".nav-item-user-menu")
  defp user_link(user), do: Query.link(user.username)
  defp sign_out_link,   do: Query.link(gettext("Sign Out"))

  test "users can sign in and out", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click(sign_in_link())
    |> fill_in(email_field(), with: user.email)
    |> fill_in(password_field(), with: "password")
    |> click(sign_in_button())
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("Welcome back %{username}!", username: user.username)

    session
    |> find(user_menu())
    |> click(user_link(user))
    |> click(sign_out_link())

    result = session
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("See you later!")
  end

  test "users can remember their password", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click(sign_in_link())
    |> fill_in(email_field(), with: user.email)
    |> fill_in(password_field(), with: "password")
    |> click(Query.checkbox(gettext("Remember me")))
    |> click(sign_in_button())
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("Welcome back %{username}!", username: user.username)

    # Delete the session cookie
    session
    |> execute_script("document.cookie = '_helheim_key=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';")

    session
    |> visit("/")
    assert Browser.current_path(session) == "/front_page"

    session
    |> find(user_menu())
    |> click(user_link(user))
    |> click(sign_out_link())

    result = session
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("See you later!")

    session
    |> visit("/")

    assert Browser.current_path(session) == "/"
  end
end
