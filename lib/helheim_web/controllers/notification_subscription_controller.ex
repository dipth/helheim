defmodule HelheimWeb.NotificationSubscriptionController do
  use HelheimWeb, :controller
  alias Helheim.NotificationSubscription
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Photo
  alias Helheim.CalendarEvent

  def update(conn, %{"profile_id" => profile_id, "type" => type, "enabled" => _}),
    do: enable(conn, type, Repo.get!(User, profile_id))
  def update(conn, %{"profile_id" => profile_id, "type" => type}),
    do: disable(conn, type, Repo.get!(User, profile_id))

  def update(conn, %{"blog_post_id" => blog_post_id, "type" => type, "enabled" => _}),
    do: enable(conn, type, Repo.get!(BlogPost, blog_post_id))
  def update(conn, %{"blog_post_id" => blog_post_id, "type" => type}),
    do: disable(conn, type, Repo.get!(BlogPost, blog_post_id))

  def update(conn, %{"forum_topic_id" => forum_topic_id, "type" => type, "enabled" => _}),
    do: enable(conn, type, Repo.get!(ForumTopic, forum_topic_id))
  def update(conn, %{"forum_topic_id" => forum_topic_id, "type" => type}),
    do: disable(conn, type, Repo.get!(ForumTopic, forum_topic_id))

  def update(conn, %{"photo_id" => photo_id, "type" => type, "enabled" => _}),
    do: enable(conn, type, Repo.get!(Photo, photo_id))
  def update(conn, %{"photo_id" => photo_id, "type" => type}),
    do: disable(conn, type, Repo.get!(Photo, photo_id))

  def update(conn, %{"calendar_event_id" => calendar_event_id, "type" => type, "enabled" => _}),
    do: enable(conn, type, Repo.get!(CalendarEvent, calendar_event_id))
  def update(conn, %{"calendar_event_id" => calendar_event_id, "type" => type}),
    do: disable(conn, type, Repo.get!(CalendarEvent, calendar_event_id))

  defp enable(conn, type, subject) do
    {:ok, _} = NotificationSubscription.enable!(current_resource(conn), type, subject)
    send_resp(conn, 200, "")
  end

  defp disable(conn, type, subject) do
    {:ok, _} = NotificationSubscription.disable!(current_resource(conn), type, subject)
    send_resp(conn, 200, "")
  end
end
