defmodule Helheim.NotificationHelpers do
  import Phoenix.HTML.Tag
  import Helheim.Router.Helpers
  import Helheim.Gettext
  alias Helheim.NotificationSubscription

  def notifications_switch(conn, user, type, %Helheim.User{} = profile) do
    enabled = find_enabled_subscription(user, type, profile) != nil
    path    = public_profile_notification_subscription_path(conn, :update, profile)
    notifications_switch(enabled, type, path)
  end

  def notifications_switch(conn, user, type, %Helheim.BlogPost{} = blog_post) do
    enabled = find_enabled_subscription(user, type, blog_post) != nil
    path    = blog_post_notification_subscription_path(conn, :update, blog_post)
    notifications_switch(enabled, type, path)
  end

  def notifications_switch(conn, user, type, %Helheim.ForumTopic{} = forum_topic) do
    enabled = find_enabled_subscription(user, type, forum_topic) != nil
    path    = forum_topic_notification_subscription_path(conn, :update, forum_topic)
    notifications_switch(enabled, type, path)
  end

  defp notifications_switch(enabled, type, path) do
    form_tag(path, method: :patch) do
      [
        content_tag(:i, "", class: "fa fa-bell mr-1"),
        content_tag(:span, gettext("Notifications:"), class: "mr-1 hidden-sm-down"),
        content_tag(:label, class: "switch switch-text switch-pill switch-primary switch-notification-subscription") do
          [
            tag(:input, type: "hidden", name: "type", value: type),
            tag(:input, type: "checkbox", name: "enabled", class: "switch-input", checked: enabled),
            content_tag(:span, "", class: "switch-label", "data-on": "On", "data-off": "Off"),
            content_tag(:span, "", class: "switch-handle")
          ]
        end
      ]
    end
  end

  defp find_enabled_subscription(user, type, subject) do
    NotificationSubscription
    |> NotificationSubscription.for_user(user)
    |> NotificationSubscription.for_type(type)
    |> NotificationSubscription.for_subject(subject)
    |> NotificationSubscription.enabled
    |> Helheim.Repo.one
  end
end
