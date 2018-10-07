defmodule HelheimWeb.VisitorLogEntryHelpers do
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Guardian.Plug, only: [current_resource: 1]
  import HelheimWeb.Router.Helpers
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.PhotoAlbum
  alias Helheim.Photo

  def visitor_count_badge(conn, %User{} = profile) do
    visitor_count_badge(
      conn,
      profile,
      profile.id,
      public_profile_visitor_log_entry_path(conn, :index, profile)
    )
  end
  def visitor_count_badge(conn, %BlogPost{} = blog_post) do
    visitor_count_badge(
      conn,
      blog_post,
      blog_post.user_id,
      public_profile_blog_post_visitor_log_entry_path(conn, :index, blog_post.user, blog_post)
    )
  end
  def visitor_count_badge(conn, %PhotoAlbum{} = photo_album) do
    visitor_count_badge(
      conn,
      photo_album,
      photo_album.user_id,
      public_profile_photo_album_visitor_log_entry_path(conn, :index, photo_album.user_id, photo_album)
    )
  end
  def visitor_count_badge(conn, %Photo{} = photo) do
    visitor_count_badge(
      conn,
      photo,
      photo.photo_album.user_id,
      public_profile_photo_album_photo_visitor_log_entry_path(conn, :index, photo.photo_album.user_id, photo.photo_album, photo)
    )
  end

  defp visitor_count_badge(conn, subject, owner_id, entries_path) do
    current_user = current_resource(conn)

    if User.admin?(current_user) || current_user.id == owner_id do
      link to: entries_path do
        content_tag :span, class: "badge badge-default" do
          [
            content_tag(:i, "", class: "fa fa-fw fa-eye"),
            {:safe, [" "]},
            {:safe, ["#{subject.visitor_count}"]}
          ]
        end
      end
    else
      content_tag :span, class: "badge badge-default" do
        [
          content_tag(:i, "", class: "fa fa-fw fa-eye"),
          {:safe, [" "]},
          {:safe, ["#{subject.visitor_count}"]}
        ]
      end
    end
  end
end
