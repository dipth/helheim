defmodule Helheim.NotificationTest do
  use Helheim.DataCase
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

  describe "list_not_clicked/1" do
    test "returns a list of all non-clicked notifications for the given recipient sorted from newest to oldest" do
      recipient = insert(:user)
      notification1 = insert(:notification, profile: insert(:user), type: "comment", recipient: recipient)
      notification2 = insert(:notification, profile: insert(:user), type: "comment", recipient: recipient)
      _notification3 = insert(:notification, profile: insert(:user), type: "comment")

      [entry1, entry2] = Notification.list_not_clicked(recipient)
      assert entry1.id == notification2.id
      assert entry2.id == notification1.id
    end

    test "it groups similar notifications together" do
      recipient = insert(:user)
      subject = insert(:user)
      notification1 = insert(:notification, profile: subject, type: "comment", recipient: recipient)
      notification2 = insert(:notification, profile: subject, type: "comment", recipient: recipient)

      [entry1] = Notification.list_not_clicked(recipient)

      assert entry1.profile_id == subject.id
      assert entry1.duplicate_count == 2
    end
  end

  describe "query_duplicate_notifications/1" do
    test "returns an ecto query that will return all similar notifications (same recipient, type and subject)" do
      recipient1 = insert(:user)
      recipient2 = insert(:user)

      subject1 = insert(:blog_post)
      subject2 = insert(:user)

      notification1 = insert(:notification, clicked_at: nil, recipient: recipient1, blog_post: subject1, type: "comment")
      notification2 = insert(:notification, clicked_at: nil, recipient: recipient1, blog_post: subject1, type: "comment")
      notification3 = insert(:notification, clicked_at: nil, recipient: recipient2, blog_post: subject1, type: "comment")
      notification4 = insert(:notification, clicked_at: nil, recipient: recipient1, profile: subject2, type: "comment")
      notification5 = insert(:notification, clicked_at: nil, recipient: recipient1, blog_post: subject1, type: "blah")
      notification6 = insert(:notification, clicked_at: DateTime.utc_now, recipient: recipient1, blog_post: subject1, type: "comment")

      notifications = Notification.query_duplicate_notifications(notification1) |> Repo.all()

      assert Enum.any?(notifications, fn(n) -> n.id == notification1.id end)
      assert Enum.any?(notifications, fn(n) -> n.id == notification2.id end)
      refute Enum.any?(notifications, fn(n) -> n.id == notification3.id end)
      refute Enum.any?(notifications, fn(n) -> n.id == notification4.id end)
      refute Enum.any?(notifications, fn(n) -> n.id == notification5.id end)
      refute Enum.any?(notifications, fn(n) -> n.id == notification6.id end)
    end
  end
end
