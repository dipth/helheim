defmodule Helheim.PrivateMessageServiceTest do
  use Helheim.ModelCase
  alias Helheim.PrivateMessageService
  alias Helheim.PrivateMessage

  @valid_body "Foo"
  @invalid_body ""

  describe "insert/3 with valid attrs" do
    setup [:create_sender_and_recipient]

    test "creates a private message from the sender to the recipient with the specified body", %{sender: sender, recipient: recipient} do
      PrivateMessageService.insert(sender, recipient, @valid_body)
      message = Repo.one!(PrivateMessage)
      assert message.sender_id == sender.id
      assert message.recipient_id == recipient.id
      assert message.body == "Foo"
    end

    test "returns :ok and a Map including a private message", %{sender: sender, recipient: recipient} do
      {:ok, %{private_message: private_message}} = PrivateMessageService.insert(sender, recipient, @valid_body)
      assert private_message
    end

    test "it trims whitespace from the body", %{sender: sender, recipient: recipient} do
      PrivateMessageService.insert(sender, recipient, "   Bar   ")
      message = Repo.one!(PrivateMessage)
      assert message.body == "Bar"
    end
  end

  describe "insert/3 with invalid body" do
    setup [:create_sender_and_recipient]

    test "does not create any private messages", %{sender: sender, recipient: recipient} do
      PrivateMessageService.insert(sender, recipient, @invalid_body)
      refute Repo.one(PrivateMessage)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{sender: sender, recipient: recipient} do
      {:error, failed_operation, failed_value, changes_so_far} = PrivateMessageService.insert(sender, recipient, @invalid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end
  end

  describe "insert/3 with same sender and recipient" do
    setup [:create_sender_and_recipient]

    test "does not create any private messages", %{sender: sender} do
      PrivateMessageService.insert(sender, sender, @valid_body)
      refute Repo.one(PrivateMessage)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{sender: sender} do
      {:error, failed_operation, failed_value, changes_so_far} = PrivateMessageService.insert(sender, sender, @valid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end
  end

  defp create_sender_and_recipient(_context) do
    sender    = insert(:user)
    recipient = insert(:user)
    [sender: sender, recipient: recipient]
  end
end
