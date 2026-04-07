defmodule Helheim.NotificationService do
  alias Ecto.Changeset
  alias Helheim.Repo
  alias HelheimWeb.NotificationChannel
  alias Helheim.NotificationSubscription
  alias Helheim.Notification
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Photo
  alias Helheim.CalendarEvent

  require Logger

  @notification_timeout 30_000

  @doc """
  Multi.run callback that spawns notification creation as a supervised background
  task, decoupled from the request lifecycle. This ensures notifications are not
  lost if the calling process exits (e.g. during deployments or connection close).

  ## Parameters

    * `_repo` - The Ecto repo (provided by Multi.run, unused)
    * `_multi_changes` - Results of prior Multi steps (provided by Multi.run, unused)
    * `type` - The notification type string (e.g. "comment", "forum_reply")
    * `subject` - The subject the notification is about (e.g. a BlogPost, ForumTopic)
    * `trigger_person` - The User who triggered the notification

  ## Returns

    * `{:ok, pid}` on successful task start

  ## Examples

      Multi.run(multi, :notify, NotificationService, :create_async!, ["comment", blog_post, user])
  """
  def create_async!(_repo, _multi_changes, type, subject, trigger_person), do: create_async!(type, subject, trigger_person)

  @doc """
  Spawns notification creation as a supervised background task under
  `Helheim.TaskSupervisor`. The task is not linked to the caller, so it
  survives request process termination.

  ## Parameters

    * `type` - The notification type string (e.g. "comment", "forum_reply")
    * `subject` - The subject the notification is about (e.g. a BlogPost, ForumTopic)
    * `trigger_person` - The User who triggered the notification

  ## Returns

    * `{:ok, pid}` on successful task start

  ## Examples

      NotificationService.create_async!("comment", blog_post, current_user)
  """
  def create_async!(type, subject, trigger_person) do
    Task.Supervisor.start_child(Helheim.TaskSupervisor, fn ->
      create!(type, subject, trigger_person)
    end)
  end

  @doc """
  Synchronously creates notifications for all matching, enabled subscriptions.
  Each notification is created in an isolated task so that a failure in one does
  not prevent the others from being created.

  ## Parameters

    * `type` - The notification type string (e.g. "comment", "forum_reply")
    * `subject` - The subject the notification is about (e.g. a BlogPost, ForumTopic)
    * `trigger_person` - The User who triggered the notification

  ## Returns

    * `{:ok, results}` where results is a list of `{:ok, notification}` or
      `{:error, reason}` tuples

  ## Examples

      NotificationService.create!("forum_reply", forum_topic, replying_user)
  """
  def create!(type, subject, trigger_person) do
    subscriptions = subscriptions(type, subject, trigger_person)

    results =
      Helheim.TaskSupervisor
      |> Task.Supervisor.async_stream_nolink(
        subscriptions,
        fn s -> notify(s, trigger_person) end,
        timeout: @notification_timeout
      )
      |> Enum.map(fn
        {:ok, result} ->
          result

        {:exit, reason} ->
          Logger.error("Notification task failed: #{inspect(reason)}")
          {:error, reason}
      end)

    {:ok, results}
  end

  @doc """
  Marks a notification and all its duplicates (same subject, type, and recipient)
  as clicked by setting `clicked_at` to the current UTC time.

  ## Parameters

    * `notification` - The Notification struct to mark as clicked

  ## Examples

      NotificationService.mark_as_clicked!(notification)
  """
  def mark_as_clicked!(notification) do
    Notification.query_duplicate_notifications(notification)
    |> Repo.update_all(set: [clicked_at: DateTime.utc_now])
  end

  # Fetches all enabled subscriptions for the given type and subject,
  # excluding subscriptions from users who have ignored the trigger person.
  defp subscriptions(type, subject, trigger_person) do
    NotificationSubscription
    |> NotificationSubscription.for_type(type)
    |> NotificationSubscription.for_subject(subject)
    |> NotificationSubscription.enabled()
    |> NotificationSubscription.with_preloads()
    |> Repo.all
    |> filter_out_ignored(trigger_person)
  end

  defp filter_out_ignored(subscriptions, trigger_person) do
    ignore_map = Helheim.Ignore.get_ignore_map()
    subscriptions
    |> Enum.reject(fn(s) ->
      (ignore_map[s.user_id] || []) |> Enum.member?(trigger_person.id)
    end)
  end

  # Skips notification when the subscriber is the same person who triggered it.
  defp notify(%NotificationSubscription{user_id: subscriber_id}, %User{id: trigger_person_id})
       when subscriber_id == trigger_person_id do
    {:error, "subscriber and trigger person is the same"}
  end

  # Creates a single notification record and pushes a real-time broadcast
  # to the recipient's channel.
  defp notify(subscription, trigger_person) do
    result =
      Changeset.change(%Notification{})
      |> Changeset.put_change(:type, subscription.type)
      |> Changeset.put_assoc(:recipient, subscription.user)
      |> Changeset.put_assoc(:trigger_person, trigger_person)
      |> put_subject(NotificationSubscription.subject(subscription))
      |> Repo.insert()

    case result do
      {:ok, notification} ->
        push_notification(notification.recipient_id)
        {:ok, notification}

      {:error, changeset} ->
        Logger.error("Failed to insert notification for user #{subscription.user_id}: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
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
