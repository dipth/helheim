defmodule Helheim.PrivateMessageService do
  import Helheim.Gettext
  import Helheim.Router.Helpers
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.PrivateMessage
  alias Helheim.NotificationService

  def insert(sender, recipient, body) do
    Multi.new
    |> Multi.insert(:private_message, build_message(sender, recipient, body))
    |> Multi.run(:ensure_different_sender_and_recipient, &ensure_different_sender_and_recipient/1)
    |> Multi.append(build_notification(sender, recipient))
    |> Repo.transaction
  end

  defp ensure_different_sender_and_recipient(%{private_message: private_message}) do
    if private_message.sender_id != private_message.recipient_id do
      {:ok, private_message}
    else
      {:error, private_message}
    end
  end

  defp build_message(sender, recipient, body) do
    PrivateMessage.create_changeset(%PrivateMessage{}, sender, recipient, %{body: body})
  end

  defp build_notification(sender, recipient) do
    attrs = %{
      title: gettext("%{username} wrote you a private message", username: sender.username),
      icon:  "envelope-o",
      path:  private_conversation_path(Helheim.Endpoint, :show, sender.id)
    }
    NotificationService.multi_insert(recipient, attrs)
  end
end
