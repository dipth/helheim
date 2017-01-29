defmodule Helheim.PrivateMessagingFlowTest do
  use Helheim.AcceptanceCase, async: true

  setup [:create_and_sign_in_user]

  test "send private messages to each other", %{session: session, user: user} do
    other_user = insert(:user)

    session
    |> visit("/profiles/#{other_user.id}")
    |> click_link(gettext("Send private message"))
    |> fill_in(gettext("Write new message:"), with: "For your eyes only!")
    |> click_on(gettext("Send Message"))

    result = session
    |> find(".alert.alert-success")
    |> text
    assert result =~ gettext("Message successfully sent")

    session
    |> click_link(gettext("Private Messages"))
    |> click_link(other_user.username)

    third_user = insert(:user)
    insert(:private_message, sender: third_user, recipient: user, conversation_id: "#{user.id}:#{third_user.id}")

    session
    |> click_link(gettext("Private Messages"))
    |> click_link(third_user.username)
  end
end
