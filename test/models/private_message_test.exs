defmodule Helheim.PrivateMessageTest do
  use Helheim.ModelCase
  alias Helheim.PrivateMessage

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
end
