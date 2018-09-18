defmodule HelheimWeb.EditProfileSettingsFlowTest do
  use HelheimWeb.AcceptanceCase#, async: true

  setup [:create_and_sign_in_user]

  # TODO: Re-enable this test when the current wysiwyg editor has been replaced
  #       with one that doesn't break integration tests
  # test "users can edit their profile settings", %{session: session, user: user} do
  #   session
  #   |> find(Query.css(".nav-item-user-menu"))
  #   |> click(Query.link(user.username))
  #   |> click(Query.link(gettext("Profile")))
  #
  #   session
  #   |> attach_file(Query.file_field("user[avatar]"), path: "test/files/1.0MB.jpg")
  #
  #   session
  #   |> click(Query.css("#user_profile_text_ifr"))
  #   |> send_keys("This is my awesome text")
  #
  #   session
  #   |> click(Query.button(gettext("Update Profile")))
  #
  #   result = session
  #   |> find(Query.css(".alert.alert-success"))
  #   |> Element.text
  #
  #   assert result =~ gettext("Profile updated!")
  # end
end
