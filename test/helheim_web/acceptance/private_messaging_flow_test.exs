defmodule HelheimWeb.PrivateMessagingFlowTest do
  use HelheimWeb.AcceptanceCase#, async: true
  alias Helheim.PrivateMessage

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

  test "users can hide private conversations", %{session: session, user: user} do
    other_user = insert(:user)

    insert_message(user, other_user, "First Message")
    insert_message(other_user, user, "Second Message")
    insert_message(user, other_user, "Third Message")
    insert_message(other_user, user, "Fourth Message")

    session
    |> visit("/private_conversations/#{other_user.id}")

    assert find(session, Query.text("Fourth Message"))

    accept_confirm session, fn(s) ->
      click(s, Query.link(gettext("Hide Conversation")))
    end

    result = session
    |> find(Query.css(".alert.alert-success"))
    |> Element.text
    assert result =~ gettext("The conversation was hidden")

    refute has_text?(session, "Fourth Message")
    refute has_text?(session, "Third Message")
    refute has_text?(session, "Second Message")
    refute has_text?(session, "First Message")
  end

  defp insert_message(sender, recipient, body) do
    conversation_id = PrivateMessage.calculate_conversation_id(sender, recipient)
    insert(
      :private_message,
      conversation_id: conversation_id,
      sender: sender,
      recipient: recipient,
      body: body,
      read_at: DateTime.utc_now
    )
  end
end
