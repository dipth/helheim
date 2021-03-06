defmodule HelheimWeb.Admin.UserView do
  use HelheimWeb, :view
  import Phoenix.HTML.Link
  alias Helheim.Comment
  alias Helheim.User

  def ip_lookup_link(nil), do: nil
  def ip_lookup_link(ip) do
    link ip, to: "http://www.ip-tracker.org/locator/ip-lookup.php?ip=#{ip}", target: "_blank"
  end

  def comment_link(conn, comment), do: link(comment.id, to: comment_path(conn, Comment.commentable(comment)))

  def comment_path(conn, %Helheim.User{} = profile), do: public_profile_comment_path(conn, :index, profile)
  def comment_path(conn, %Helheim.BlogPost{} = blog_post), do: public_profile_blog_post_path(conn, :show, blog_post.user_id, blog_post)
  def comment_path(conn, %Helheim.Photo{} = photo), do: public_profile_photo_album_photo_path(conn, :show, photo.photo_album.user_id, photo.photo_album_id, photo)
  def comment_path(conn, %Helheim.CalendarEvent{} = event), do: calendar_event_path(conn, :show, event)

  def block_user_link(_conn, current_user, user) when current_user == user, do: user.username
  def block_user_link(conn, _current_user, user), do: link(user.username, to: admin_user_path(conn, :show, user))
end
