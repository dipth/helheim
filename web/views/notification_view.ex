defmodule Helheim.NotificationView do
  use Helheim.Web, :view
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Helheim.Gettext
  alias Helheim.{Notification, User, BlogPost, PhotoAlbum, Photo, ForumTopic}

  def notifications_count_badge(conn, opts \\ %{}), do: notifications_count_badge(conn, opts, conn.assigns[:notifications_count])
  def notifications_count_badge(conn, opts, 0), do: notifications_count_badge(conn, opts, "")
  def notifications_count_badge(_conn, opts, count) do
    css_class = String.trim("badge badge-notification-count badge-pill badge-danger #{opts[:class]}")
    content_tag(:span, count, class: css_class)
  end

  def notification_item(conn, notification, opts \\ %{}) do
    subject = Notification.subject(notification)
    icon    = notification_icon(notification.type)
    text    = notification_text(notification.trigger_person, notification.type, subject)

    link(to: notification_path(conn, :show, notification), class: opts[:class]) do
      [
        content_tag(:i, "", class: icon),
        text
      ]
    end
  end

  defp notification_text(trigger_person, "comment", %User{} = profile) do
    gettext "%{who} wrote a comment in the guest book: %{what}", who: trigger_person.username, what: profile.username
  end
  defp notification_text(trigger_person, "comment", %BlogPost{} = blog_post) do
    gettext "%{who} wrote a comment on the blog post: %{what}", who: trigger_person.username, what: blog_post.title
  end
  defp notification_text(trigger_person, "comment", %PhotoAlbum{} = photo_album) do
    gettext "%{who} wrote a comment on the photo album: %{what}", who: trigger_person.username, what: photo_album.title
  end
  defp notification_text(trigger_person, "comment", %Photo{} = photo) do
    gettext "%{who} wrote a comment on the photo: %{what}", who: trigger_person.username, what: photo.title
  end
  defp notification_text(trigger_person, "forum_reply", %ForumTopic{} = forum_topic) do
    gettext "%{who} wrote a reply to the forum topic: %{what}", who: trigger_person.username, what: forum_topic.title
  end

  defp notification_icon("comment"), do: "fa fa-fw fa-comment-o"
  defp notification_icon("forum_reply"), do: "fa fa-fw fa-comments-o"
end
