defmodule Helheim.PasswordResetFlowTest do
  use Helheim.AcceptanceCase#, async: true
  alias Helheim.Repo
  alias Helheim.User

  defp success_alert, do: Query.css(".alert.alert-success")

  test "users can reset their password", %{session: session} do
    user = insert(:user)

    result = session
    |> visit("/")
    |> click(Query.link(gettext("Sign In")))
    |> click(Query.link(gettext("Click here if you forgot your password")))
    |> fill_in(Query.text_field(gettext("E-mail")), with: user.email)
    |> click(Query.button(gettext("Reset Password")))
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("Password reset instructions sent!")

    user = Repo.get(User, user.id)
    result = session
    |> visit("/password_resets/#{user.password_reset_token}")
    |> fill_in(Query.text_field(gettext("New Password")), with: "myNewPassword")
    |> fill_in(Query.text_field(gettext("Confirm Password")), with: "myNewPassword")
    |> click(Query.button(gettext("Change Password")))
    |> find(success_alert())
    |> Element.text
    assert result =~ gettext("Your password has now been changed and you have been signed in!")
  end
end
