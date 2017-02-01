defmodule Helheim.EditAccountSettingsFlowTest do
  use Helheim.AcceptanceCase#, async: true

  setup [:create_and_sign_in_user]

  test "users can edit their account settings", %{session: session, user: user} do
    session
    |> find(".nav-item-user-menu")
    |> click_link(user.username)
    |> click_link(gettext("Account"))

    session
    |> fill_in(gettext("Name"), with: "New Name")
    |> fill_in(gettext("E-mail"), with: "new@email.com")
    |> fill_in(gettext("user_password"), with: "newpassword")
    |> fill_in(gettext("user_password_confirmation"), with: "newpassword")
    |> fill_in(gettext("user_existing_password"), with: "password")
    |> click_on(gettext("Update Account"))

    result = session
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Account updated!")
  end
end
