defmodule HelheimWeb.NotificationSubscriptionControllerTest do
  use HelheimWeb.ConnCase
  alias Helheim.NotificationSubscription

  @type_attr "comment"

  ##############################################################################
  # update/2 for a profile
  describe "update/2 for a profile when signed in" do
    setup [:create_and_sign_in_user, :create_profile]

    test "creates an enabled subscription for the user for the given profile when enabling", %{conn: conn, user: user, profile: profile} do
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.one(NotificationSubscription)
      assert conn.status             == 200
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.type       == @type_attr
      assert subscription.enabled    == true
    end

    test "enables an existing disabled subscription for the user for the given profile when enabling", %{conn: conn, user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: profile, type: @type_attr, enabled: false)
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status             == 200
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.type       == @type_attr
      assert subscription.enabled    == true
    end

    test "enables an existing enabled subscription for the user for the given profile when enabling", %{conn: conn, user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: profile, type: @type_attr, enabled: true)
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status             == 200
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.type       == @type_attr
      assert subscription.enabled    == true
    end

    test "does not change subscriptions for other users", %{conn: conn, user: user, profile: profile} do
      subscription = insert(:notification_subscription, profile: profile, type: @type_attr, enabled: false)
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status             == 200
      refute subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      assert subscription.type       == @type_attr
      assert subscription.enabled    == false
    end

    test "does not change subscriptions for other profiles", %{conn: conn, user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: insert(:user), type: @type_attr, enabled: false)
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status             == 200
      assert subscription.user_id    == user.id
      refute subscription.profile_id == profile.id
      assert subscription.type       == @type_attr
      assert subscription.enabled    == false
    end

    test "does not change subscriptions with other types", %{conn: conn, user: user, profile: profile} do
      subscription = insert(:notification_subscription, user: user, profile: profile, type: "blog_post", enabled: false)
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status             == 200
      assert subscription.user_id    == user.id
      assert subscription.profile_id == profile.id
      refute subscription.type       == @type_attr
      assert subscription.enabled    == false
    end

    test "it does not create a subscription but instead shows an error page if the profile does not exist", %{conn: conn, profile: profile} do
      assert_error_sent :not_found, fn ->
        put conn, "/profiles/#{profile.id + 1}/notification_subscription", type: @type_attr, enabled: "1"
      end
      refute Repo.one(NotificationSubscription)
    end
  end

  describe "update/2 for a profile when not signed in" do
    setup [:create_profile]

    test "does not create any subscription and instead redirects to the login page", %{conn: conn, profile: profile} do
      conn = put conn, "/profiles/#{profile.id}/notification_subscription", type: @type_attr, enabled: "1"
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute Repo.one(NotificationSubscription)
    end
  end

  ##############################################################################
  # update/2 for a blog post
  describe "update/2 for a blog post when signed in" do
    setup [:create_and_sign_in_user, :create_blog_post]

    test "creates an enabled subscription for the user for the given blog post when enabling", %{conn: conn, user: user, blog_post: blog_post} do
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.one(NotificationSubscription)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == true
    end

    test "enables an existing disabled subscription for the user for the given blog post when enabling", %{conn: conn, user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: blog_post, type: @type_attr, enabled: false)
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == true
    end

    test "enables an existing enabled subscription for the user for the given blog post when enabling", %{conn: conn, user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: blog_post, type: @type_attr, enabled: true)
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == true
    end

    test "does not change subscriptions for other users", %{conn: conn, user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, blog_post: blog_post, type: @type_attr, enabled: false)
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      refute subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == false
    end

    test "does not change subscriptions for other blog posts", %{conn: conn, user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: insert(:blog_post), type: @type_attr, enabled: false)
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      refute subscription.blog_post_id == blog_post.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == false
    end

    test "does not change subscriptions with other types", %{conn: conn, user: user, blog_post: blog_post} do
      subscription = insert(:notification_subscription, user: user, blog_post: blog_post, type: "blog_post", enabled: false)
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.blog_post_id == blog_post.id
      refute subscription.type         == @type_attr
      assert subscription.enabled      == false
    end

    test "it does not create a subscription but instead shows an error page if the blog post does not exist", %{conn: conn, blog_post: blog_post} do
      assert_error_sent :not_found, fn ->
        put conn, "/blog_posts/#{blog_post.id + 1}/notification_subscription", type: @type_attr, enabled: "1"
      end
      refute Repo.one(NotificationSubscription)
    end
  end

  describe "update/2 for a blog post when not signed in" do
    setup [:create_blog_post]

    test "does not create any subscription and instead redirects to the login page", %{conn: conn, blog_post: blog_post} do
      conn = put conn, "/blog_posts/#{blog_post.id}/notification_subscription", type: @type_attr, enabled: "1"
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute Repo.one(NotificationSubscription)
    end
  end

  ##############################################################################
  # update/2 for a forum topic
  describe "update/2 for a forum topic when signed in" do
    setup [:create_and_sign_in_user, :create_forum_topic]

    test "creates an enabled subscription for the user for the given forum topic when enabling", %{conn: conn, user: user, forum_topic: forum_topic} do
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      subscription = Repo.one(NotificationSubscription)
      assert conn.status                 == 200
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.type           == "forum_reply"
      assert subscription.enabled        == true
    end

    test "enables an existing disabled subscription for the user for the given forum topic when enabling", %{conn: conn, user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "forum_reply", enabled: false)
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                 == 200
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.type           == "forum_reply"
      assert subscription.enabled        == true
    end

    test "enables an existing enabled subscription for the user for the given forum topic when enabling", %{conn: conn, user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "forum_reply", enabled: true)
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                 == 200
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.type           == "forum_reply"
      assert subscription.enabled        == true
    end

    test "does not change subscriptions for other users", %{conn: conn, user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, forum_topic: forum_topic, type: "forum_reply", enabled: false)
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                 == 200
      refute subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      assert subscription.type           == "forum_reply"
      assert subscription.enabled        == false
    end

    test "does not change subscriptions for other forum topics", %{conn: conn, user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: insert(:forum_topic), type: "forum_reply", enabled: false)
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                 == 200
      assert subscription.user_id        == user.id
      refute subscription.forum_topic_id == forum_topic.id
      assert subscription.type           == "forum_reply"
      assert subscription.enabled        == false
    end

    test "does not change subscriptions with other types", %{conn: conn, user: user, forum_topic: forum_topic} do
      subscription = insert(:notification_subscription, user: user, forum_topic: forum_topic, type: "blog_post", enabled: false)
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                 == 200
      assert subscription.user_id        == user.id
      assert subscription.forum_topic_id == forum_topic.id
      refute subscription.type           == "forum_reply"
      assert subscription.enabled        == false
    end

    test "it does not create a subscription but instead shows an error page if the forum topic does not exist", %{conn: conn, forum_topic: forum_topic} do
      assert_error_sent :not_found, fn ->
        put conn, "/forum_topics/#{forum_topic.id + 1}/notification_subscription", type: "forum_reply", enabled: "1"
      end
      refute Repo.one(NotificationSubscription)
    end
  end

  describe "update/2 for a forum topic when not signed in" do
    setup [:create_forum_topic]

    test "does not create any subscription and instead redirects to the login page", %{conn: conn, forum_topic: forum_topic} do
      conn = put conn, "/forum_topics/#{forum_topic.id}/notification_subscription", type: "forum_reply", enabled: "1"
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute Repo.one(NotificationSubscription)
    end
  end

  ##############################################################################
  # update/2 for a photo
  describe "update/2 for a photo when signed in" do
    setup [:create_and_sign_in_user, :create_photo]

    test "creates an enabled subscription for the user for the given photo when enabling", %{conn: conn, user: user, photo: photo} do
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.one(NotificationSubscription)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.photo_id     == photo.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == true
    end

    test "enables an existing disabled subscription for the user for the given photo when enabling", %{conn: conn, user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: photo, type: @type_attr, enabled: false)
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.photo_id     == photo.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == true
    end

    test "enables an existing enabled subscription for the user for the given photo when enabling", %{conn: conn, user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: photo, type: @type_attr, enabled: true)
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.photo_id     == photo.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == true
    end

    test "does not change subscriptions for other users", %{conn: conn, user: user, photo: photo} do
      subscription = insert(:notification_subscription, photo: photo, type: @type_attr, enabled: false)
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      refute subscription.user_id      == user.id
      assert subscription.photo_id     == photo.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == false
    end

    test "does not change subscriptions for other photos", %{conn: conn, user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, blog_post: insert(:blog_post), type: @type_attr, enabled: false)
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      refute subscription.photo_id     == photo.id
      assert subscription.type         == @type_attr
      assert subscription.enabled      == false
    end

    test "does not change subscriptions with other types", %{conn: conn, user: user, photo: photo} do
      subscription = insert(:notification_subscription, user: user, photo: photo, type: "blog_post", enabled: false)
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status               == 200
      assert subscription.user_id      == user.id
      assert subscription.photo_id     == photo.id
      refute subscription.type         == @type_attr
      assert subscription.enabled      == false
    end

    test "it does not create a subscription but instead shows an error page if the photo does not exist", %{conn: conn, photo: photo} do
      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id + 1}/notification_subscription", type: @type_attr, enabled: "1"
      end
      refute Repo.one(NotificationSubscription)
    end
  end

  describe "update/2 for a photo when not signed in" do
    setup [:create_photo]

    test "does not create any subscription and instead redirects to the login page", %{conn: conn, photo: photo} do
      conn = put conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/notification_subscription", type: @type_attr, enabled: "1"
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute Repo.one(NotificationSubscription)
    end
  end

  ##############################################################################
  # update/2 for a calendar_event
  describe "update/2 for a calendar_event when signed in" do
    setup [:create_and_sign_in_user, :create_calendar_event]

    test "creates an enabled subscription for the user for the given calendar_event when enabling", %{conn: conn, user: user, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.one(NotificationSubscription)
      assert conn.status                    == 200
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.type              == @type_attr
      assert subscription.enabled           == true
    end

    test "enables an existing disabled subscription for the user for the given calendar_event when enabling", %{conn: conn, user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: calendar_event, type: @type_attr, enabled: false)
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                    == 200
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.type              == @type_attr
      assert subscription.enabled           == true
    end

    test "enables an existing enabled subscription for the user for the given calendar_event when enabling", %{conn: conn, user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: calendar_event, type: @type_attr, enabled: true)
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                    == 200
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.type              == @type_attr
      assert subscription.enabled           == true
    end

    test "does not change subscriptions for other users", %{conn: conn, user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, calendar_event: calendar_event, type: @type_attr, enabled: false)
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                    == 200
      refute subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      assert subscription.type              == @type_attr
      assert subscription.enabled           == false
    end

    test "does not change subscriptions for other calendar_events", %{conn: conn, user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, profile: insert(:user), type: @type_attr, enabled: false)
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                    == 200
      assert subscription.user_id           == user.id
      refute subscription.calendar_event_id == calendar_event.id
      assert subscription.type              == @type_attr
      assert subscription.enabled           == false
    end

    test "does not change subscriptions with other types", %{conn: conn, user: user, calendar_event: calendar_event} do
      subscription = insert(:notification_subscription, user: user, calendar_event: calendar_event, type: "blog_post", enabled: false)
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      subscription = Repo.get(NotificationSubscription, subscription.id)
      assert conn.status                    == 200
      assert subscription.user_id           == user.id
      assert subscription.calendar_event_id == calendar_event.id
      refute subscription.type              == @type_attr
      assert subscription.enabled           == false
    end

    test "it does not create a subscription but instead shows an error page if the calendar_event does not exist", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        put conn, "/calendar_events/#{calendar_event.id + 1}/notification_subscription", type: @type_attr, enabled: "1"
      end
      refute Repo.one(NotificationSubscription)
    end
  end

  describe "update/2 for a calendar_event when not signed in" do
    setup [:create_calendar_event]

    test "does not create any subscription and instead redirects to the login page", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}/notification_subscription", type: @type_attr, enabled: "1"
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute Repo.one(NotificationSubscription)
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

  defp create_forum_topic(_context) do
    [forum_topic: insert(:forum_topic)]
  end

  defp create_photo(_context) do
    [photo: insert(:photo)]
  end

  defp create_calendar_event(_context) do
    [calendar_event: insert(:calendar_event)]
  end
end
