defmodule Helheim.PrivateMessageService do
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.PrivateMessage
  alias Helheim.NotificationChannel

  def insert(sender, recipient, body) do
    Multi.new
    |> Multi.insert(:private_message, build_message(sender, recipient, body))
    |> Multi.run(:ensure_different_sender_and_recipient, &ensure_different_sender_and_recipient/1)
    |> Multi.run(:push_notification, &push_notification/1)
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

  defp push_notification(%{private_message: private_message}) do
    NotificationChannel.broadcast_notification(private_message.recipient_id)
    {:ok, private_message}
  end
end
