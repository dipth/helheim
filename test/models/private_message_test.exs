defmodule Helheim.PrivateMessageTest do
  use Helheim.ModelCase
  alias Helheim.PrivateMessage

  describe "by_or_for/2" do
    test "returns messages where the specified user is the recipient" do
      recipient   = insert(:user)
      message     = insert(:private_message, recipient: recipient, conversation_id: "1:2")
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(recipient) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      assert Enum.member?(message_ids, message.id)
    end

    test "returns messages where the specified user is the sender" do
      sender      = insert(:user)
      message     = insert(:private_message, sender: sender, conversation_id: "1:2")
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(sender) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      assert Enum.member?(message_ids, message.id)
    end

    test "does not return messages between other users" do
      user    = insert(:user)
      message = insert(:private_message, conversation_id: "1:2")
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(user) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      refute Enum.member?(message_ids, message.id)
    end

    test "does not return messages where the specified user is the recipient and the message is hidden by recipient" do
      recipient   = insert(:user)
      message     = insert(:private_message, recipient: recipient, conversation_id: "1:2", hidden_by_recipient_at: DateTime.utc_now)
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(recipient) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      refute Enum.member?(message_ids, message.id)
    end

    test "return messages where the specified user is the recipient and the message is hidden by sender" do
      recipient   = insert(:user)
      message     = insert(:private_message, recipient: recipient, conversation_id: "1:2", hidden_by_sender_at: DateTime.utc_now)
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(recipient) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      assert Enum.member?(message_ids, message.id)
    end

    test "does not return messages where the specified user is the sender and the message is hidden by sender" do
      sender      = insert(:user)
      message     = insert(:private_message, sender: sender, conversation_id: "1:2", hidden_by_sender_at: DateTime.utc_now)
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(sender) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      refute Enum.member?(message_ids, message.id)
    end

    test "does not return messages where the specified user is the sender and the message is hidden by recipient" do
      sender      = insert(:user)
      message     = insert(:private_message, sender: sender, conversation_id: "1:2", hidden_by_recipient_at: DateTime.utc_now)
      message_ids = PrivateMessage |> PrivateMessage.by_or_for(sender) |> Repo.all |> Enum.map(fn(m) -> m.id end)
      assert Enum.member?(message_ids, message.id)
    end
  end

  describe "calculate_conversation_id/2" do
    test "it returns a concatenation of the ids of both users in numerical order" do
      first_user = insert(:user)
      second_user = insert(:user)
      assert PrivateMessage.calculate_conversation_id(second_user, first_user) == "#{first_user.id}:#{second_user.id}"
      assert PrivateMessage.calculate_conversation_id(first_user, second_user) == "#{first_user.id}:#{second_user.id}"
    end

    test "it works when using integers instead of users" do
      first_user  = insert(:user)
      second_user = insert(:user)
      assert PrivateMessage.calculate_conversation_id(first_user.id, second_user.id) == "#{first_user.id}:#{second_user.id}"
      assert PrivateMessage.calculate_conversation_id(first_user.id, second_user) == "#{first_user.id}:#{second_user.id}"
      assert PrivateMessage.calculate_conversation_id(first_user, second_user.id) == "#{first_user.id}:#{second_user.id}"
    end
  end

  describe "unread?/2" do
    test "returns true if read_at is nil and the recipient is the same as the specified user" do
      recipient = insert(:user)
      message = insert(:private_message, recipient: recipient, read_at: nil, conversation_id: "1:2")
      assert PrivateMessage.unread?(message, recipient)
    end

    test "returns false if read_at is not nil" do
      recipient = insert(:user)
      message = insert(:private_message, recipient: recipient, read_at: DateTime.utc_now, conversation_id: "1:2")
      refute PrivateMessage.unread?(message, recipient)
    end

    test "returns false if the recipient is not the same as the specified user" do
      recipient = insert(:user)
      message = insert(:private_message, read_at: DateTime.utc_now, conversation_id: "1:2")
      refute PrivateMessage.unread?(message, recipient)
    end
  end

  describe "mark_as_read!/2" do
    test "it sets the read_at value of all messages with the specified conversation_id and recipient" do
      recipient = insert(:user)
      message_1 = insert(:private_message, recipient: recipient, read_at: nil, conversation_id: "1:2")
      message_2 = insert(:private_message, recipient: recipient, read_at: nil, conversation_id: "1:2")
      PrivateMessage.mark_as_read!("1:2", recipient)
      message_1 = Repo.get(PrivateMessage, message_1.id)
      message_2 = Repo.get(PrivateMessage, message_2.id)
      assert message_1.read_at
      assert message_2.read_at
    end

    test "it does not set the read_at value of messages with a different conversation_id" do
      recipient = insert(:user)
      message   = insert(:private_message, recipient: recipient, read_at: nil, conversation_id: "1:3")
      PrivateMessage.mark_as_read!("1:2", recipient)
      message = Repo.get(PrivateMessage, message.id)
      refute message.read_at
    end

    test "it does not set the read_at value of messages with a different recipient" do
      recipient = insert(:user)
      message   = insert(:private_message, read_at: nil, conversation_id: "1:2")
      PrivateMessage.mark_as_read!("1:2", recipient)
      message = Repo.get(PrivateMessage, message.id)
      refute message.read_at
    end
  end

  describe "hide!/2 when passing a sender" do
    test "it sets only the hidden_by_sender_at value of all messages with the specified conversation_id and sender" do
      sender    = insert(:user)
      message_1 = insert(:private_message, sender: sender, conversation_id: "1:2")
      message_2 = insert(:private_message, sender: sender, conversation_id: "1:2")
      PrivateMessage.hide!("1:2", %{sender: sender})
      message_1 = Repo.get(PrivateMessage, message_1.id)
      message_2 = Repo.get(PrivateMessage, message_2.id)
      assert message_1.hidden_by_sender_at
      refute message_1.hidden_by_recipient_at
      assert message_2.hidden_by_sender_at
      refute message_2.hidden_by_recipient_at
    end

    test "it does not set the hidden_by_sender_at value of messages with a different conversation_id" do
      sender  = insert(:user)
      message = insert(:private_message, sender: sender, conversation_id: "1:3")
      PrivateMessage.hide!("1:2", %{sender: sender})
      message = Repo.get(PrivateMessage, message.id)
      refute message.hidden_by_sender_at
    end

    test "it does not set the hidden_by_sender_at value of messages with a different sender" do
      sender  = insert(:user)
      message = insert(:private_message, conversation_id: "1:2")
      PrivateMessage.hide!("1:2", %{sender: sender})
      message = Repo.get(PrivateMessage, message.id)
      refute message.hidden_by_sender_at
    end
  end

  describe "hide!/2 when passing a recipient" do
    test "it sets only the hidden_by_recipient_at value of all messages with the specified conversation_id and recipient" do
      recipient = insert(:user)
      message_1 = insert(:private_message, recipient: recipient, conversation_id: "1:2")
      message_2 = insert(:private_message, recipient: recipient, conversation_id: "1:2")
      PrivateMessage.hide!("1:2", %{recipient: recipient})
      message_1 = Repo.get(PrivateMessage, message_1.id)
      message_2 = Repo.get(PrivateMessage, message_2.id)
      assert message_1.hidden_by_recipient_at
      refute message_1.hidden_by_sender_at
      assert message_2.hidden_by_recipient_at
      refute message_2.hidden_by_sender_at
    end

    test "it does not set the hidden_by_recipient_at value of messages with a different conversation_id" do
      recipient = insert(:user)
      message   = insert(:private_message, recipient: recipient, conversation_id: "1:3")
      PrivateMessage.hide!("1:2", %{recipient: recipient})
      message = Repo.get(PrivateMessage, message.id)
      refute message.hidden_by_recipient_at
    end

    test "it does not set the hidden_by_recipient_at value of messages with a different recipient" do
      recipient = insert(:user)
      message   = insert(:private_message, conversation_id: "1:2")
      PrivateMessage.hide!("1:2", %{recipient: recipient})
      message = Repo.get(PrivateMessage, message.id)
      refute message.hidden_by_recipient_at
    end
  end

  describe "hide!/2 when passing a user" do
    test "it sets hidden_by_recipient_at for messages recieved by the user and hidden_by_sender_at for messages sent by the user" do
      user = insert(:user)
      message_1 = insert(:private_message, recipient: user, conversation_id: "1:2")
      message_2 = insert(:private_message, sender: user, conversation_id: "1:2")
      PrivateMessage.hide!("1:2", %{user: user})
      message_1 = Repo.get(PrivateMessage, message_1.id)
      message_2 = Repo.get(PrivateMessage, message_2.id)
      assert message_1.hidden_by_recipient_at
      refute message_1.hidden_by_sender_at
      refute message_2.hidden_by_recipient_at
      assert message_2.hidden_by_sender_at
    end
  end
end
