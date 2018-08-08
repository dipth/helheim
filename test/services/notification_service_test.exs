defmodule Helheim.NotificationServiceTest do
  use Helheim.ModelCase
  alias Helheim.NotificationService
  alias Helheim.Notification

  ##############################################################################
  # create!/3 for a comment on a profile
  describe "create!/3 for a comment on a profile" do
    setup [:create_user, :create_trigger_person, :create_profile]

    test "creates a notification for a subscription that matches the arguments",
      %{user: user, trigger_person: trigger_person, profile: profile} do

      insert(:notification_subscription, user: user, type: "comment", profile: profile, enabled: true)
      NotificationService.create!("comment", profile, trigger_person)
      notification = Repo.one!(Notification)
      assert notification.recipient_id      == user.id
      assert notification.type              == "comment"
      assert notification.profile_id        == profile.id
      assert notification.trigger_person_id == trigger_person.id
    end

    test "does not create a notification for a subscription with a different type value",
      %{user: user, trigger_person: trigger_person, profile: profile} do

      insert(:notification_subscription, user: user, type: "foo", profile: profile, enabled: true)
      NotificationService.create!("comment", profile, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription with a different subject",
      %{user: user, trigger_person: trigger_person, profile: profile} do

      insert(:notification_subscription, user: user, type: "comment", profile: insert(:user), enabled: true)
      NotificationService.create!("comment", profile, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription that is disabled",
      %{user: user, trigger_person: trigger_person, profile: profile} do

      insert(:notification_subscription, user: user, type: "comment", profile: profile, enabled: false)
      NotificationService.create!("comment", profile, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification if the trigger person is the same as the subscriber",
      %{trigger_person: trigger_person, profile: profile} do

      insert(:notification_subscription, user: trigger_person, type: "comment", profile: profile, enabled: true)
      NotificationService.create!("comment", profile, trigger_person)
      refute Repo.one(Notification)
    end
  end

  ##############################################################################
  # create!/3 for a comment on a blog post
  describe "create!/3 for a comment on a blog post" do
    setup [:create_user, :create_trigger_person, :create_blog_post]

    test "creates a notification for a subscription that matches the arguments",
      %{user: user, trigger_person: trigger_person, blog_post: blog_post} do

      insert(:notification_subscription, user: user, type: "comment", blog_post: blog_post, enabled: true)
      NotificationService.create!("comment", blog_post, trigger_person)
      notification = Repo.one!(Notification)
      assert notification.recipient_id      == user.id
      assert notification.type              == "comment"
      assert notification.blog_post_id      == blog_post.id
      assert notification.trigger_person_id == trigger_person.id
    end

    test "does not create a notification for a subscription with a different type value",
      %{user: user, trigger_person: trigger_person, blog_post: blog_post} do

      insert(:notification_subscription, user: user, type: "foo", blog_post: blog_post, enabled: true)
      NotificationService.create!("comment", blog_post, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription with a different subject",
      %{user: user, trigger_person: trigger_person, blog_post: blog_post} do

      insert(:notification_subscription, user: user, type: "comment", blog_post: insert(:blog_post), enabled: true)
      NotificationService.create!("comment", blog_post, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription that is disabled",
      %{user: user, trigger_person: trigger_person, blog_post: blog_post} do

      insert(:notification_subscription, user: user, type: "comment", blog_post: blog_post, enabled: false)
      NotificationService.create!("comment", blog_post, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification if the trigger person is the same as the subscriber",
      %{trigger_person: trigger_person, blog_post: blog_post} do

      insert(:notification_subscription, user: trigger_person, type: "comment", blog_post: blog_post, enabled: true)
      NotificationService.create!("comment", blog_post, trigger_person)
      refute Repo.one(Notification)
    end
  end

  ##############################################################################
  # create!/3 for a comment on a photo
  describe "create!/3 for a comment on a photo" do
    setup [:create_user, :create_trigger_person, :create_photo]

    test "creates a notification for a subscription that matches the arguments",
      %{user: user, trigger_person: trigger_person, photo: photo} do

      insert(:notification_subscription, user: user, type: "comment", photo: photo, enabled: true)
      NotificationService.create!("comment", photo, trigger_person)
      notification = Repo.one!(Notification)
      assert notification.recipient_id      == user.id
      assert notification.type              == "comment"
      assert notification.photo_id          == photo.id
      assert notification.trigger_person_id == trigger_person.id
    end

    test "does not create a notification for a subscription with a different type value",
      %{user: user, trigger_person: trigger_person, photo: photo} do

      insert(:notification_subscription, user: user, type: "foo", photo: photo, enabled: true)
      NotificationService.create!("comment", photo, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription with a different subject",
      %{user: user, trigger_person: trigger_person, photo: photo} do

      insert(:notification_subscription, user: user, type: "comment", photo: insert(:photo), enabled: true)
      NotificationService.create!("comment", photo, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription that is disabled",
      %{user: user, trigger_person: trigger_person, photo: photo} do

      insert(:notification_subscription, user: user, type: "comment", photo: photo, enabled: false)
      NotificationService.create!("comment", photo, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification if the trigger person is the same as the subscriber",
      %{trigger_person: trigger_person, photo: photo} do

      insert(:notification_subscription, user: trigger_person, type: "comment", photo: photo, enabled: true)
      NotificationService.create!("comment", photo, trigger_person)
      refute Repo.one(Notification)
    end
  end

  ##############################################################################
  # create!/3 for a reply to a forum topic
  describe "create!/3 for a reply to a forum topic" do
    setup [:create_user, :create_trigger_person, :create_forum_topic]

    test "creates a notification for a subscription that matches the arguments",
      %{user: user, trigger_person: trigger_person, forum_topic: forum_topic} do

      insert(:notification_subscription, user: user, type: "forum_reply", forum_topic: forum_topic, enabled: true)
      NotificationService.create!("forum_reply", forum_topic, trigger_person)
      notification = Repo.one!(Notification)
      assert notification.recipient_id      == user.id
      assert notification.type              == "forum_reply"
      assert notification.forum_topic_id    == forum_topic.id
      assert notification.trigger_person_id == trigger_person.id
    end

    test "does not create a notification for a subscription with a different type value",
      %{user: user, trigger_person: trigger_person, forum_topic: forum_topic} do

      insert(:notification_subscription, user: user, type: "foo", forum_topic: forum_topic, enabled: true)
      NotificationService.create!("forum_reply", forum_topic, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription with a different subject",
      %{user: user, trigger_person: trigger_person, forum_topic: forum_topic} do

      insert(:notification_subscription, user: user, type: "forum_reply", forum_topic: insert(:forum_topic), enabled: true)
      NotificationService.create!("forum_reply", forum_topic, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription that is disabled",
      %{user: user, trigger_person: trigger_person, forum_topic: forum_topic} do

      insert(:notification_subscription, user: user, type: "forum_reply", forum_topic: forum_topic, enabled: false)
      NotificationService.create!("forum_reply", forum_topic, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification if the trigger person is the same as the subscriber",
      %{trigger_person: trigger_person, forum_topic: forum_topic} do

      insert(:notification_subscription, user: trigger_person, type: "comment", forum_topic: forum_topic, enabled: true)
      NotificationService.create!("comment", forum_topic, trigger_person)
      refute Repo.one(Notification)
    end
  end

  ##############################################################################
  # create!/3 for a comment on a calendar_event
  describe "create!/3 for a comment on a calendar_event" do
    setup [:create_user, :create_trigger_person, :create_calendar_event]

    test "creates a notification for a subscription that matches the arguments",
      %{user: user, trigger_person: trigger_person, calendar_event: calendar_event} do

      insert(:notification_subscription, user: user, type: "comment", calendar_event: calendar_event, enabled: true)
      NotificationService.create!("comment", calendar_event, trigger_person)
      notification = Repo.one!(Notification)
      assert notification.recipient_id      == user.id
      assert notification.type              == "comment"
      assert notification.calendar_event_id == calendar_event.id
      assert notification.trigger_person_id == trigger_person.id
    end

    test "does not create a notification for a subscription with a different type value",
      %{user: user, trigger_person: trigger_person, calendar_event: calendar_event} do

      insert(:notification_subscription, user: user, type: "foo", calendar_event: calendar_event, enabled: true)
      NotificationService.create!("comment", calendar_event, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription with a different subject",
      %{user: user, trigger_person: trigger_person, calendar_event: calendar_event} do

      insert(:notification_subscription, user: user, type: "comment", calendar_event: insert(:calendar_event), enabled: true)
      NotificationService.create!("comment", calendar_event, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification for a subscription that is disabled",
      %{user: user, trigger_person: trigger_person, calendar_event: calendar_event} do

      insert(:notification_subscription, user: user, type: "comment", calendar_event: calendar_event, enabled: false)
      NotificationService.create!("comment", calendar_event, trigger_person)
      refute Repo.one(Notification)
    end

    test "does not create a notification if the trigger person is the same as the subscriber",
      %{trigger_person: trigger_person, calendar_event: calendar_event} do

      insert(:notification_subscription, user: trigger_person, type: "comment", calendar_event: calendar_event, enabled: true)
      NotificationService.create!("comment", calendar_event, trigger_person)
      refute Repo.one(Notification)
    end
  end

  ##############################################################################
  # mark_as_clicked!/1
  describe "mark_as_clicked!/1" do
    test "updates the clicked_at value of the notification to the current utc time" do
      {:ok, notification} = insert(:notification, clicked_at: nil)
                            |> NotificationService.mark_as_clicked!
      {:ok, time_diff, _, _} = Calendar.DateTime.diff(notification.clicked_at, DateTime.utc_now)
      assert time_diff < 10
    end
  end

  ##############################################################################
  # SETUP
  defp create_trigger_person(_context), do: [trigger_person: insert(:user)]
  defp create_profile(_context),        do: [profile: insert(:user)]
  defp create_blog_post(_context),      do: [blog_post: insert(:blog_post)]
  defp create_forum_topic(_context),    do: [forum_topic: insert(:forum_topic)]
  defp create_photo(_context),          do: [photo: insert(:photo)]
  defp create_calendar_event(_context), do: [calendar_event: insert(:calendar_event)]
end
