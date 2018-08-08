defmodule Helheim.NotificationView do
  use Helheim.Web, :view
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Helheim.Gettext
  alias Helheim.{Notification, User, BlogPost, PhotoAlbum, Photo, ForumTopic, CalendarEvent}

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
    gettext "%{who} wrote a comment in the guest book: %{what}", who: trigger_person_name(trigger_person), what: profile.username
  end
  defp notification_text(trigger_person, "comment", %BlogPost{} = blog_post) do
    gettext "%{who} wrote a comment on the blog post: %{what}", who: trigger_person_name(trigger_person), what: blog_post.title
  end
  defp notification_text(trigger_person, "comment", %PhotoAlbum{} = photo_album) do
    gettext "%{who} wrote a comment on the photo album: %{what}", who: trigger_person_name(trigger_person), what: photo_album.title
  end
  defp notification_text(trigger_person, "comment", %Photo{} = photo) do
    gettext "%{who} wrote a comment on the photo: %{what}", who: trigger_person_name(trigger_person), what: photo.title
  end
  defp notification_text(trigger_person, "forum_reply", %ForumTopic{} = forum_topic) do
    gettext "%{who} wrote a reply to the forum topic: %{what}", who: trigger_person_name(trigger_person), what: forum_topic.title
  end
  defp notification_text(trigger_person, "comment", %CalendarEvent{} = calendar_event) do
    gettext "%{who} wrote a comment on the calendar event: %{what}", who: trigger_person_name(trigger_person), what: calendar_event.title
  end

  defp notification_icon("comment"), do: "fa fa-fw fa-comment-o"
  defp notification_icon("forum_reply"), do: "fa fa-fw fa-comments-o"

  defp trigger_person_name(nil), do: gettext("User deleted")
  defp trigger_person_name(trigger_person), do: trigger_person.username
end
