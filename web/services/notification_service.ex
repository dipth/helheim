defmodule Helheim.NotificationService do
  alias Ecto.Changeset
  alias Helheim.Repo
  alias Helheim.NotificationChannel
  alias Helheim.NotificationSubscription
  alias Helheim.Notification
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Photo
  alias Helheim.CalendarEvent

  def create_async!(_multi_changes, type, subject, trigger_person), do: create_async!(type, subject, trigger_person)
  def create_async!(type, subject, trigger_person) do
    {:ok, Task.async(fn -> create!(type, subject, trigger_person) end)}
  end

  def create!(type, subject, trigger_person) do
    subscriptions = subscriptions(type, subject)
    notifications = Parallel.pmap(subscriptions, fn(s) -> notify!(s, trigger_person) end)
    {:ok, notifications}
  end

  def mark_as_clicked!(notification) do
    Notification.query_duplicate_notifications(notification)
    |> Repo.update_all(set: [clicked_at: DateTime.utc_now])
  end

  defp subscriptions(type, subject) do
    NotificationSubscription
    |> NotificationSubscription.for_type(type)
    |> NotificationSubscription.for_subject(subject)
    |> NotificationSubscription.enabled()
    |> NotificationSubscription.with_preloads()
    |> Repo.all
  end

  defp notify!(%NotificationSubscription{user_id: subscriber_id}, %User{id: trigger_person_id}) when subscriber_id == trigger_person_id,
    do: {:error, "subscriber and trigger person is the same"}
  defp notify!(subscription, trigger_person) do
    {:ok, notification} =
      Changeset.change(%Notification{})
      |> Changeset.put_change(:type, subscription.type)
      |> Changeset.put_assoc(:recipient, subscription.user)
      |> Changeset.put_assoc(:trigger_person, trigger_person)
      |> put_subject(NotificationSubscription.subject(subscription))
      |> Repo.insert()
    push_notification(notification.recipient_id)
  end

  defp put_subject(changeset, %User{} = profile),                 do: changeset |> Changeset.put_assoc(:profile, profile)
  defp put_subject(changeset, %BlogPost{} = blog_post),           do: changeset |> Changeset.put_assoc(:blog_post, blog_post)
  defp put_subject(changeset, %ForumTopic{} = forum_topic),       do: changeset |> Changeset.put_assoc(:forum_topic, forum_topic)
  defp put_subject(changeset, %Photo{} = photo),                  do: changeset |> Changeset.put_assoc(:photo, photo)
  defp put_subject(changeset, %CalendarEvent{} = calendar_event), do: changeset |> Changeset.put_assoc(:calendar_event, calendar_event)

  defp push_notification(recipient_id) do
    NotificationChannel.broadcast_notification(recipient_id)
  end
end
