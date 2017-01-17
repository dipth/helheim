defmodule Altnation.EditProfileSettingsFlowTest do
  use Altnation.AcceptanceCase, async: true

  # TODO: Enable this test when you figure out how to use Wallaby with the
  #       Trumbowyg editor:
  #       https://github.com/keathley/wallaby/issues/129
  # test "users can edit their profile settings", %{session: session} do
  #   user = insert(:user)
  #
  #   session
  #   |> visit("/sessions/new")
  #   |> fill_in(gettext("E-mail"), with: user.email)
  #   |> fill_in(gettext("Password"), with: "password")
  #   |> click_on(gettext("Sign In"))
  #
  #   session
  #   |> find(".nav-item-user-menu")
  #   |> click_link(user.username)
  #   |> click_link(gettext("Profile"))
  #
  #   session
  #   |> fill_in(".trumbowyg-editor", with: "This is my profile text")
  #   |> click_on(gettext("Update Profile"))
  #
  #   TODO: Also test the profile photo upload
  #
  #   result = session
  #   |> find(".alert.alert-success")
  #   |> text
  #
  #   assert result =~ gettext("Profile Updated!")
  # end
end
