defmodule Helheim.NotificationService do
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Notification
  alias Helheim.NotificationChannel

  def multi_insert(recipient, attrs \\ %{}) do
    Multi.new
    |> insert_or_update_notification(recipient, attrs)
    |> Multi.run(:push_notification, &push_notification/1)
  end

  defp insert_or_update_notification(multi, recipient, attrs) do
    notification = find_existing_unread_notification(recipient, attrs)
    case notification do
      nil ->
        changeset = build_new_notification(recipient, attrs)
        Multi.insert(multi, :notification, changeset)
      _ ->
        changeset = Ecto.Changeset.change notification, inserted_at: DateTime.utc_now
        Multi.update(multi, :notification, changeset)
    end
  end

  defp find_existing_unread_notification(recipient, attrs) do
    Ecto.assoc(recipient, :notifications)
    |> Notification.unread
    |> Repo.get_by(attrs)
  end

  defp build_new_notification(recipient, attrs) do
    Notification.changeset(%Notification{}, attrs)
    |> Ecto.Changeset.put_assoc(:user, recipient)
  end

  defp push_notification(%{notification: notification}) do
    {NotificationChannel.broadcast_notification(notification), notification}
  end
end
