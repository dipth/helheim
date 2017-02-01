defmodule Helheim.PasswordResetFlowTest do
  use Helheim.AcceptanceCase#, async: true
  alias Helheim.Repo
  alias Helheim.User

  test "users can reset their password", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click_link(gettext("Sign In"))
    |> click_link(gettext("Click here if you forgot your password"))
    |> fill_in(gettext("E-mail"), with: user.email)
    |> click_on(gettext("Reset Password"))
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("Password reset instructions sent!")

    user = Repo.get(User, user.id)
    result = session
    |> visit("/password_resets/#{user.password_reset_token}")
    |> fill_in(gettext("New Password"), with: "myNewPassword")
    |> fill_in(gettext("Confirm Password"), with: "myNewPassword")
    |> click_on(gettext("Change Password"))
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("Your password has now been changed and you have been signed in!")
  end
end
