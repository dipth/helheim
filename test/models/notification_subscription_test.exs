defmodule Helheim.NotificationSubscriptionTest do
  use Helheim.ModelCase
  alias Helheim.NotificationSubscription

  @valid_attrs %{type: "comment", enabled: true}

  ##############################################################################
  # changeset/2
  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = NotificationSubscription.changeset(%NotificationSubscription{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a type" do
      changeset = NotificationSubscription.changeset(%NotificationSubscription{}, Map.delete(@valid_attrs, :type))
      refute changeset.valid?
    end

    test "it does not allow an unknown type" do
      changeset = NotificationSubscription.changeset(%NotificationSubscription{}, Map.merge(@valid_attrs, %{type: "foo"}))
      refute changeset.valid?
    end
  end

  ##############################################################################
  # for_user/2
  describe "for_user/2" do
    test "finds only subscriptions for the given user" do
      user_1          = insert(:user)
      user_2          = insert(:user)
      subscription_1  = insert(:notification_subscription, user: user_1)
      _subscription_2 = insert(:notification_subscription, user: user_2)
      [subscription] = NotificationSubscription |> NotificationSubscription.for_user(user_1) |> Repo.all
      assert subscription.id == subscription_1.id
    end
  end

  ##############################################################################
  # for_type/2
  describe "for_type/2" do
    test "finds only subscriptions with the given type" do
      subscription_1  = insert(:notification_subscription, type: "blog_post")
      _subscription_2 = insert(:notification_subscription, type: "comment")
      [subscription] = NotificationSubscription |> NotificationSubscription.for_type("blog_post") |> Repo.all
      assert subscription.id == subscription_1.id
    end
  end

  ##############################################################################
  # for_subject/2
  describe "for_subject/2" do
    test "returns only subscriptions for the specified profile" do
      profile         = insert(:user)
      blog_post       = insert(:blog_post)
      subscription_1  = insert(:notification_subscription, profile: profile)
      _subscription_2 = insert(:notification_subscription, blog_post: blog_post)
      [subscription] = NotificationSubscription |> NotificationSubscription.for_subject(profile) |> Repo.all
      assert subscription.id == subscription_1.id
    end

    test "returns only subscriptions for the specified blog post" do
      blog_post       = insert(:blog_post)
      profile         = insert(:user)
      subscription_1  = insert(:notification_subscription, blog_post: blog_post)
      _subscription_2 = insert(:notification_subscription, profile: profile)
      [subscription] = NotificationSubscription |> NotificationSubscription.for_subject(blog_post) |> Repo.all
      assert subscription.id == subscription_1.id
    end

    test "returns only subscriptions for the specified forum topic" do
      topic           = insert(:forum_topic)
      blog_post       = insert(:blog_post)
      subscription_1  = insert(:notification_subscription, forum_topic: topic)
      _subscription_2 = insert(:notification_subscription, blog_post: blog_post)
      [subscription] = NotificationSubscription |> NotificationSubscription.for_subject(topic) |> Repo.all
      assert subscription.id == subscription_1.id
    end

    test "returns only subscriptions for the specified photo" do
      photo           = insert(:photo)
      blog_post       = insert(:blog_post)
      subscription_1  = insert(:notification_subscription, photo: photo)
      _subscription_2 = insert(:notification_subscription, blog_post: blog_post)
      [subscription] = NotificationSubscription |> NotificationSubscription.for_subject(photo) |> Repo.all
      assert subscription.id == subscription_1.id
    end

    test "returns only subscriptions for the specified calendar_event" do
      calendar_event  = insert(:calendar_event)
      blog_post       = insert(:blog_post)
      subscription_1  = insert(:notification_subscription, calendar_event: calendar_event)
      _subscription_2 = insert(:notification_subscription, blog_post: blog_post)
      [subscription] = NotificationSubscription |> NotificationSubscription.for_subject(calendar_event) |> Repo.all
      assert subscription.id == subscription_1.id
    end
  end

  ##############################################################################
  # enabled/1
  describe "enabled/1" do
    test "returns only enabled subscriptions" do
      subscription_1  = insert(:notification_subscription, enabled: true)
      _subscription_2 = insert(:notification_subscription, enabled: false)
      [subscription] = NotificationSubscription |> NotificationSubscription.enabled() |> Repo.all
      assert subscription.id == subscription_1.id
    end
  end

  ##############################################################################
  # with_preloads/1
  describe "with_preloads/1" do
    test "preloads the associated user" do
      insert(:notification_subscription)
      [subscription] = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.all
      assert subscription.user
    end

    test "preloads the associated profile" do
      insert(:notification_subscription, profile: insert(:user))
      [subscription] = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.all
      assert subscription.profile
    end

    test "preloads the associated blog post" do
      insert(:notification_subscription, blog_post: insert(:blog_post))
      [subscription] = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.all
      assert subscription.blog_post
    end

    test "preloads the associated forum topic" do
      insert(:notification_subscription, forum_topic: insert(:forum_topic))
      [subscription] = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.all
      assert subscription.forum_topic
    end

    test "preloads the associated photo" do
      insert(:notification_subscription, photo: insert(:photo))
      [subscription] = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.all
      assert subscription.photo
    end

    test "preloads the associated calendar_event" do
      insert(:notification_subscription, calendar_event: insert(:calendar_event))
      [subscription] = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.all
      assert subscription.calendar_event
    end
  end

  ##############################################################################
  # subject/1
  describe "subject/1" do
    test "returns the profile if it is set" do
      profile = insert(:user)
      id      = profile.id
      insert(:notification_subscription, profile: profile)
      subscription = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.one
      %Helheim.User{id: ^id} = NotificationSubscription.subject(subscription)
    end

    test "returns the blog post if it is set" do
      blog_post = insert(:blog_post)
      id        = blog_post.id
      insert(:notification_subscription, blog_post: blog_post)
      subscription = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.one
      %Helheim.BlogPost{id: ^id} = NotificationSubscription.subject(subscription)
    end

    test "returns the forum topic if it is set" do
      forum_topic = insert(:forum_topic)
      id          = forum_topic.id
      insert(:notification_subscription, forum_topic: forum_topic)
      subscription = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.one
      %Helheim.ForumTopic{id: ^id} = NotificationSubscription.subject(subscription)
    end

    test "returns the photo if it is set" do
      photo = insert(:photo)
      id    = photo.id
      insert(:notification_subscription, photo: photo)
      subscription = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.one
      %Helheim.Photo{id: ^id} = NotificationSubscription.subject(subscription)
    end

    test "returns the calendar_event if it is set" do
      calendar_event = insert(:calendar_event)
      id             = calendar_event.id
      insert(:notification_subscription, calendar_event: calendar_event)
      subscription = NotificationSubscription |> NotificationSubscription.with_preloads() |> Repo.one
      %Helheim.CalendarEvent{id: ^id} = NotificationSubscription.subject(subscription)
    end
  end

  ##############################################################################
  # enable!/3 for comments on a profile
  describe "enable! for comments on a profile" do
    setup [:create_user, :create_profile]

    test "it creates a new enabled subscription when none exists", %{user: user, profile: profile} do
      NotificationSubscription.enable!(user, "comment", profile)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.enabled    == true
    end

    test "it marks an existing subscription as enabled", %{user: user, profile: profile} do
      insert(:notification_subscription, user: user, profile: profile, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", profile)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.enabled    == true
    end

    test "it does not touch another users subscription", %{user: user, profile: profile} do
      subscription = insert(:notification_subscription, profile: profile, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", profile)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other profiles", %{user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: insert(:user), type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", profile)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other types of events", %{user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: profile, type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "comment", profile)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end
  end

  ##############################################################################
  # enable!/3 for comments on a blog post
  describe "enable! for comments on a blog post" do
    setup [:create_user, :create_blog_post]

    test "it creates a new enabled subscription when none exists", %{user: user, blog_post: blog_post} do
      NotificationSubscription.enable!(user, "comment", blog_post)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.enabled      == true
    end

    test "it marks an existing subscription as enabled", %{user: user, blog_post: blog_post} do
      insert(:notification_subscription, user: user, blog_post: blog_post, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", blog_post)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.enabled      == true
    end

    test "it does not touch another users subscription", %{user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, blog_post: blog_post, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", blog_post)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other blog posts", %{user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: insert(:blog_post), type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", blog_post)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other types of events", %{user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: blog_post, type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "comment", blog_post)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end
  end

  ##############################################################################
  # enable!/3 for comments on a photo
  describe "enable! for comments on a photo" do
    setup [:create_user, :create_photo]

    test "it creates a new enabled subscription when none exists", %{user: user, photo: photo} do
      NotificationSubscription.enable!(user, "comment", photo)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id  == user.id
      assert subscription.photo_id == photo.id
      assert subscription.enabled  == true
    end

    test "it marks an existing subscription as enabled", %{user: user, photo: photo} do
      insert(:notification_subscription, user: user, photo: photo, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", photo)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id  == user.id
      assert subscription.photo_id == photo.id
      assert subscription.enabled  == true
    end

    test "it does not touch another users subscription", %{user: user, photo: photo} do
      subscription = insert(:notification_subscription, photo: photo, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", photo)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other blog posts", %{user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: insert(:photo), type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", photo)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other types of events", %{user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: photo, type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "comment", photo)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end
  end

  ##############################################################################
  # enable!/3 for replies on a forum topic
  describe "enable! for replies on a forum topic" do
    setup [:create_user, :create_forum_topic]

    test "it creates a new enabled subscription when none exists", %{user: user, forum_topic: forum_topic} do
      NotificationSubscription.enable!(user, "forum_reply", forum_topic)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.enabled        == true
    end

    test "it marks an existing subscription as enabled", %{user: user, forum_topic: forum_topic} do
      insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "forum_reply", forum_topic)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.enabled        == true
    end

    test "it does not touch another users subscription", %{user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, forum_topic: forum_topic, type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "forum_reply", forum_topic)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other blog posts", %{user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: insert(:forum_topic), type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "forum_reply", forum_topic)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other types of events", %{user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "forum_reply", forum_topic)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end
  end

  ##############################################################################
  # enable!/3 for comments on a calendar_event
  describe "enable! for comments on a calendar_event" do
    setup [:create_user, :create_calendar_event]

    test "it creates a new enabled subscription when none exists", %{user: user, calendar_event: calendar_event} do
      NotificationSubscription.enable!(user, "comment", calendar_event)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.enabled           == true
    end

    test "it marks an existing subscription as enabled", %{user: user, calendar_event: calendar_event} do
      insert(:notification_subscription, user: user, calendar_event: calendar_event, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", calendar_event)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.enabled           == true
    end

    test "it does not touch another users subscription", %{user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, calendar_event: calendar_event, type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", calendar_event)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other calendar_events", %{user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: insert(:calendar_event), type: "comment", enabled: false)
      NotificationSubscription.enable!(user, "comment", calendar_event)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end

    test "it does not touch subscriptions for other types of events", %{user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: calendar_event, type: "forum_reply", enabled: false)
      NotificationSubscription.enable!(user, "comment", calendar_event)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == false
    end
  end

  ##############################################################################
  # disable!/3 for comments on a profile
  describe "disable! for comments on a profile" do
    setup [:create_user, :create_profile]

    test "it creates a new disabled subscription when none exists", %{user: user, profile: profile} do
      NotificationSubscription.disable!(user, "comment", profile)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.enabled    == false
    end

    test "it marks an existing subscription as disabled", %{user: user, profile: profile} do
      insert(:notification_subscription, user: user, profile: profile, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", profile)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.enabled    == false
    end

    test "it does not touch another users subscription", %{user: user, profile: profile} do
      subscription = insert(:notification_subscription, profile: profile, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", profile)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other profiles", %{user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: insert(:user), type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", profile)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other types of events", %{user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: profile, type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "comment", profile)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end
  end

  ##############################################################################
  # disable!/3 for comments on a blog post
  describe "disable! for comments on a blog post" do
    setup [:create_user, :create_blog_post]

    test "it creates a new disabled subscription when none exists", %{user: user, blog_post: blog_post} do
      NotificationSubscription.disable!(user, "comment", blog_post)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.enabled      == false
    end

    test "it marks an existing subscription as disabled", %{user: user, blog_post: blog_post} do
      insert(:notification_subscription, user: user, blog_post: blog_post, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", blog_post)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.enabled      == false
    end

    test "it does not touch another users subscription", %{user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, blog_post: blog_post, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", blog_post)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other blog posts", %{user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: insert(:blog_post), type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", blog_post)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other types of events", %{user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: blog_post, type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "comment", blog_post)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end
  end

  ##############################################################################
  # disable!/3 for comments on a photo
  describe "disable! for comments on a photo" do
    setup [:create_user, :create_photo]

    test "it creates a new disabled subscription when none exists", %{user: user, photo: photo} do
      NotificationSubscription.disable!(user, "comment", photo)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id  == user.id
      assert subscription.photo_id == photo.id
      assert subscription.enabled  == false
    end

    test "it marks an existing subscription as disabled", %{user: user, photo: photo} do
      insert(:notification_subscription, user: user, photo: photo, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", photo)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id  == user.id
      assert subscription.photo_id == photo.id
      assert subscription.enabled  == false
    end

    test "it does not touch another users subscription", %{user: user, photo: photo} do
      subscription = insert(:notification_subscription, photo: photo, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", photo)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other blog posts", %{user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: insert(:photo), type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", photo)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other types of events", %{user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: photo, type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "comment", photo)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end
  end

  ##############################################################################
  # disable!/3 for replies on a forum topic
  describe "disable! for replies on a forum topic" do
    setup [:create_user, :create_forum_topic]

    test "it creates a new disabled subscription when none exists", %{user: user, forum_topic: forum_topic} do
      NotificationSubscription.disable!(user, "forum_reply", forum_topic)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.enabled        == false
    end

    test "it marks an existing subscription as disabled", %{user: user, forum_topic: forum_topic} do
      insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "forum_reply", forum_topic)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.enabled        == false
    end

    test "it does not touch another users subscription", %{user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, forum_topic: forum_topic, type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "forum_reply", forum_topic)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other blog posts", %{user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: insert(:forum_topic), type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "forum_reply", forum_topic)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other types of events", %{user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "forum_reply", forum_topic)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end
  end

  ##############################################################################
  # disable!/3 for comments on a calendar_event
  describe "disable! for comments on a calendar_event" do
    setup [:create_user, :create_calendar_event]

    test "it creates a new disabled subscription when none exists", %{user: user, calendar_event: calendar_event} do
      NotificationSubscription.disable!(user, "comment", calendar_event)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.enabled           == false
    end

    test "it marks an existing subscription as disabled", %{user: user, calendar_event: calendar_event} do
      insert(:notification_subscription, user: user, calendar_event: calendar_event, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", calendar_event)
      subscription = Repo.one(NotificationSubscription)
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.enabled           == false
    end

    test "it does not touch another users subscription", %{user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, calendar_event: calendar_event, type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", calendar_event)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other calendar_events", %{user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: insert(:calendar_event), type: "comment", enabled: true)
      NotificationSubscription.disable!(user, "comment", calendar_event)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end

    test "it does not touch subscriptions for other types of events", %{user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: calendar_event, type: "forum_reply", enabled: true)
      NotificationSubscription.disable!(user, "comment", calendar_event)
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert subscription.enabled == true
    end
  end

  ##############################################################################
  # SETUP
  defp create_profile(_context) do
    [profile: insert(:user)]
  end

  defp create_blog_post(_context) do
    [blog_post: insert(:blog_post)]
  end

  defp create_photo(_context) do
    [photo: insert(:photo)]
  end

  defp create_forum_topic(_context) do
    [forum_topic: insert(:forum_topic)]
  end

  defp create_calendar_event(_context) do
    [calendar_event: insert(:calendar_event)]
  end
end
