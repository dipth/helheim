defmodule Helheim.PrivateMessageServiceTest do
  use Helheim.ModelCase
  import Helheim.Router.Helpers
  import Mock
  alias Helheim.PrivateMessageService
  alias Helheim.PrivateMessage
  alias Helheim.Notification
  alias Helheim.NotificationChannel

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

    test "creates a notification for the recipient", %{sender: sender, recipient: recipient} do
      PrivateMessageService.insert(sender, recipient, @valid_body)
      notification = Repo.one!(Notification)
      assert notification.user_id == recipient.id
      assert notification.title == gettext("%{username} wrote you a private message", username: sender.username)
      assert notification.path == private_conversation_path(Helheim.Endpoint, :show, sender.id)
    end

    test_with_mock "it sends the notification to the NotificationChannel", %{sender: sender, recipient: recipient},
      NotificationChannel, [], [broadcast_notification: fn(_notification) -> :ok end] do

      PrivateMessageService.insert(sender, recipient, @valid_body)
      assert called NotificationChannel.broadcast_notification(:_)
    end

    test_with_mock "it does not sends the notification to the NotificationChannel if anything failed", %{sender: sender, recipient: recipient},
      NotificationChannel, [], [broadcast_notification: fn(_notification) -> :ok end] do

      PrivateMessageService.insert(sender, recipient, @invalid_body)
      refute called NotificationChannel.broadcast_notification(:_)
    end

    test "returns :ok and a Map including a private message and a notification", %{sender: sender, recipient: recipient} do
      {:ok, %{private_message: private_message, notification: notification}} = PrivateMessageService.insert(sender, recipient, @valid_body)
      assert private_message
      assert notification
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

    test "does not create any notifications", %{sender: sender, recipient: recipient} do
      PrivateMessageService.insert(sender, recipient, @invalid_body)
      refute Repo.one(Notification)
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

    test "does not create any notifications", %{sender: sender} do
      PrivateMessageService.insert(sender, sender, @valid_body)
      refute Repo.one(Notification)
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
