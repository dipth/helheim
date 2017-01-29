defmodule Helheim.EditProfileSettingsFlowTest do
  use Helheim.AcceptanceCase, async: true

  setup [:create_and_sign_in_user]

  test "users can edit their profile settings", %{session: session, user: user} do
    session
    |> find(".nav-item-user-menu")
    |> click_link(user.username)
    |> click_link(gettext("Profile"))

    session
    |> attach_file("user[avatar]", path: "test/files/1.0MB.jpg")

    session
    |> execute_script("$('#profile_text_editor .ql-editor').html('This is my awesome text');")

    session
    |> click_on(gettext("Update Profile"))

    result = session
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Profile updated!")
  end
end