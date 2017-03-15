defmodule Helheim.EditAccountSettingsFlowTest do
  use Helheim.AcceptanceCase#, async: true

  defp user_menu,       do: Query.css(".nav-item-user-menu")
  defp user_link(user), do: Query.link(user.username)
  defp account_link,    do: Query.link(gettext("Account"))
  defp success_alert,   do: Query.css(".alert.alert-success")

  setup [:create_and_sign_in_user]

  test "users can edit their account settings", %{session: session, user: user} do
    session
    |> find(user_menu())
    |> click(user_link(user))
    |> click(account_link())

    session
    |> fill_in(Query.text_field(gettext("Name")), with: "New Name")
    |> fill_in(Query.text_field(gettext("E-mail")), with: "new@email.com")
    |> fill_in(Query.text_field(gettext("user_password")), with: "newpassword")
    |> fill_in(Query.text_field(gettext("user_password_confirmation")), with: "newpassword")
    |> fill_in(Query.text_field(gettext("user_existing_password")), with: "password")
    |> click(Query.button(gettext("Update Account")))

    result = session
    |> find(success_alert())
    |> Element.text

    assert result =~ gettext("Account updated!")
  end

  # TODO: Enable when wallaby / phoenixjs supports alert interaction
  # test "users can delete their account", %{session: session, user: user} do
  #   session
  #   |> find(user_menu())
  #   |> click(user_link(user))
  #   |> click(account_link())
  #
  #   session
  #   |> click(Query.link(gettext("Delete Account")))
  #
  #   result = session
  #   |> find(success_alert())
  #   |> Element.text
  #
  #   assert result =~ gettext("Hope to see you again some time!")
  # end
end
