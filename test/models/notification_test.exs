defmodule Helheim.NotificationTest do
  use Helheim.ModelCase
  alias Helheim.Notification

  describe "newest/1" do
    test "orders newer notifications before older ones" do
      notification_1 = insert(:notification)
      notification_2 = insert(:notification)
      notifications  = Notification |> Notification.newest |> Repo.all
      [first, last]  = notifications
      assert first.id == notification_2.id
      assert last.id  == notification_1.id
    end
  end

  describe "not_clicked/1" do
    test "only returns notifications where clicked_at is null" do
      notification_1  = insert(:notification, clicked_at: nil)
      _notification_2 = insert(:notification, clicked_at: DateTime.utc_now)
      notifications = Notification |> Notification.not_clicked |> Repo.all
      [first] = notifications
      assert first.id == notification_1.id
    end
  end

  describe "with_preloads/1" do
    test "preloads the associated trigger_person" do
      notification = insert(:notification, trigger_person: insert(:user))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.trigger_person
    end

    test "preloads the associated profile" do
      notification = insert(:notification, profile: insert(:user))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.profile
    end

    test "preloads the associated blog_post" do
      notification = insert(:notification, blog_post: insert(:blog_post))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.blog_post
    end

    test "preloads the associated photo_album" do
      notification = insert(:notification, photo_album: insert(:photo_album))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.photo_album
    end

    test "preloads the associated photo" do
      notification = insert(:notification, photo: insert(:photo))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.photo
    end

    test "preloads the associated forum_topic" do
      notification = insert(:notification, forum_topic: insert(:forum_topic))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.forum_topic
    end

    test "preloads the associated calendar_event" do
      notification = insert(:notification, calendar_event: insert(:calendar_event))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      assert notification.calendar_event
    end
  end

  describe "subject/1" do
    test "returns the associated profile" do
      notification = insert(:notification, profile: insert(:user))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      %Helheim.User{} = Notification.subject(notification)
    end

    test "returns the associated blog_post" do
      notification = insert(:notification, blog_post: insert(:blog_post))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      %Helheim.BlogPost{} = Notification.subject(notification)
    end

    test "returns the associated photo_album" do
      notification = insert(:notification, photo_album: insert(:photo_album))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      %Helheim.PhotoAlbum{} = Notification.subject(notification)
    end

    test "returns the associated photo" do
      notification = insert(:notification, photo: insert(:photo))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      %Helheim.Photo{} = Notification.subject(notification)
    end

    test "returns the associated forum_topic" do
      notification = insert(:notification, forum_topic: insert(:forum_topic))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      %Helheim.ForumTopic{} = Notification.subject(notification)
    end

    test "returns the associated calendar_event" do
      notification = insert(:notification, calendar_event: insert(:calendar_event))
      notification = Notification |> Notification.with_preloads |> Repo.get!(notification.id)
      %Helheim.CalendarEvent{} = Notification.subject(notification)
    end
  end
end
