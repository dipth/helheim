defmodule Helheim.PrivateMessagingFlowTest do
  use Helheim.AcceptanceCase#, async: true

  defp private_messages_link, do: Query.link(gettext("Private Messages"))

  setup [:create_and_sign_in_user]

  test "users can send private messages to each other", %{session: session, user: user} do
    other_user = insert(:user)

    session
    |> visit("/profiles/#{other_user.id}")
    |> click(Query.link(gettext("Send private message")))
    |> fill_in(Query.text_field(gettext("Write new message:")), with: "For your eyes only!")
    |> click(Query.button(gettext("Send Message")))

    result = session
    |> find(Query.css(".alert.alert-success"))
    |> Element.text
    assert result =~ gettext("Message successfully sent")

    session
    |> click(private_messages_link())
    |> click(Query.link(other_user.username))

    third_user = insert(:user)
    insert(:private_message, sender: third_user, recipient: user, conversation_id: "#{user.id}:#{third_user.id}")

    session
    |> click(private_messages_link())
    |> click(Query.link(third_user.username))
  end
end
