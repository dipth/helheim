defmodule Helheim.NotificationController do
  use Helheim.Web, :controller
  alias Helheim.Notification
  alias Helheim.NotificationService

  def show(conn, %{"id" => id}) do
    user                = current_resource(conn)
    {:ok, notification} = assoc(user, :notifications)
                          |> Notification.with_preloads
                          |> Repo.get!(id)
                          |> NotificationService.mark_as_clicked!

    redirect(conn, to: redirect_path(conn, Notification.subject(notification)))
  end

  defp redirect_path(conn, %Helheim.User{} = profile),
    do: public_profile_comment_path(conn, :index, profile)
  defp redirect_path(conn, %Helheim.BlogPost{} = blog_post),
    do: public_profile_blog_post_path(conn, :show, blog_post.user_id, blog_post)
  defp redirect_path(conn, %Helheim.PhotoAlbum{} = photo_album),
    do: public_profile_photo_album_path(conn, :show, photo_album.user_id, photo_album)
  defp redirect_path(conn, %Helheim.Photo{} = photo) do
    photo_album = Repo.get!(Helheim.PhotoAlbum, photo.photo_album_id)
    public_profile_photo_album_photo_path(conn, :show, photo_album.user_id, photo_album, photo)
  end
  defp redirect_path(conn, %Helheim.ForumTopic{} = forum_topic),
    do: forum_forum_topic_path(conn, :show, forum_topic.forum_id, forum_topic)
end
