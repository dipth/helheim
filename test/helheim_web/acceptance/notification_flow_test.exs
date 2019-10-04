defmodule HelheimWeb.NotificationFlowTest do
  use HelheimWeb.AcceptanceCase#, async: true
  alias Helheim.NotificationSubscription

  setup [:create_and_sign_in_user]

  defp comments_div,        do: Query.css(".comments")
  defp subscription_switch, do: Query.css(".switch-notification-subscription .switch-handle")

  test "users can subscribe and unsubscribe for notifications for profile comments from the profile page", %{session: session, user: user} do
    profile = insert(:user)

    session = session
    |> visit("/profiles/#{profile.id}")
    |> find(comments_div())

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.one!(NotificationSubscription)
    assert subscription.user_id    == user.id
    assert subscription.profile_id == profile.id
    assert subscription.type       == "comment"
    assert subscription.enabled    == true

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.get(NotificationSubscription, subscription.id)
    assert subscription.enabled == false
  end

  test "users can subscribe and unsubscribe for notifications for profile comments from the guestbook page", %{session: session, user: user} do
    profile = insert(:user)

    session = session
    |> visit("/profiles/#{profile.id}/comments")
    |> find(comments_div())

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.one!(NotificationSubscription)
    assert subscription.user_id    == user.id
    assert subscription.profile_id == profile.id
    assert subscription.type       == "comment"
    assert subscription.enabled    == true

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.get(NotificationSubscription, subscription.id)
    assert subscription.enabled == false
  end

  test "users can subscribe and unsubscribe for notifications for blog post comments from the blog post page", %{session: session, user: user} do
    blog_post = insert(:blog_post)

    session = session
    |> visit("/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}")
    |> find(comments_div())

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.one!(NotificationSubscription)
    assert subscription.user_id      == user.id
    assert subscription.blog_post_id == blog_post.id
    assert subscription.type         == "comment"
    assert subscription.enabled      == true

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.get(NotificationSubscription, subscription.id)
    assert subscription.enabled == false
  end

  test "users can subscribe and unsubscribe for notifications for forum replies from the forum topic page", %{session: session, user: user} do
    forum_topic = insert(:forum_topic)

    session = session
    |> visit("/forums/#{forum_topic.forum.id}/forum_topics/#{forum_topic.id}")

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.one!(NotificationSubscription)
    assert subscription.user_id        == user.id
    assert subscription.forum_topic_id == forum_topic.id
    assert subscription.type           == "forum_reply"
    assert subscription.enabled        == true

    session
    |> click(subscription_switch())

    # Wait for the request to go through
    Process.sleep(100)

    subscription = Repo.get(NotificationSubscription, subscription.id)
    assert subscription.enabled == false
  end

  # test "users can see and click notifications from the header", %{session: session, user: user} do
  #   insert(:notification, user: user, title: "Super Notification!", path: "/profiles/#{user.id}")
  #
  #   session
  #   |> visit("/front_page")
  #
  #   assert find(session, Query.css("#nav-item-notifications .badge", text: "1"))
  #
  #   session
  #   |> click(Query.css("#nav-link-notifications"))
  #   |> click(Query.link("Super Notification!"))
  #
  #   assert current_path(session) == "/profiles/#{user.id}"
  # end
end
