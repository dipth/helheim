defmodule Altnation.EditAccountSettingsFlowTest do
  use Altnation.AcceptanceCase, async: true
  import Altnation.Factory

  test "users can edit their account settings", %{session: session} do
    user = insert(:user)

    session
    |> visit("/sessions/new")
    |> fill_in(gettext("E-mail"), with: user.email)
    |> fill_in(gettext("Password"), with: "password")
    |> click_on(gettext("Sign In"))

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
