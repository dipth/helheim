defmodule Helheim.VisitorLogEntryView do
  use Helheim.Web, :view
  alias Helheim.Avatar
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.PhotoAlbum
  alias Helheim.Photo

  def crumbs(conn, %User{} = profile) do
    content_tag :ol, class: "breadcrumb" do
      [
        content_tag(:li, class: "breadcrumb-item") do
          link(profile.username, to: public_profile_path(conn, :show, profile))
        end,
        content_tag(:li, gettext("Visitors"), class: "breadcrumb-item active")
      ]
    end
  end

  def crumbs(conn, %BlogPost{} = blog_post) do
    profile = conn.assigns[:profile]
    content_tag :ol, class: "breadcrumb" do
      [
        content_tag(:li, class: "breadcrumb-item") do
          link(profile.username, to: public_profile_path(conn, :show, profile))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(gettext("Blog Posts"), to: public_profile_blog_post_path(conn, :index, profile))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(blog_post.title, to: public_profile_blog_post_path(conn, :show, profile, blog_post))
        end,
        content_tag(:li, gettext("Visitors"), class: "breadcrumb-item active")
      ]
    end
  end

  def crumbs(conn, %PhotoAlbum{} = photo_album) do
    profile = conn.assigns[:profile]
    content_tag :ol, class: "breadcrumb" do
      [
        content_tag(:li, class: "breadcrumb-item") do
          link(profile.username, to: public_profile_path(conn, :show, profile))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(gettext("Photo Albums"), to: public_profile_photo_album_path(conn, :index, profile))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(photo_album.title, to: public_profile_photo_album_path(conn, :show, profile, photo_album))
        end,
        content_tag(:li, gettext("Visitors"), class: "breadcrumb-item active")
      ]
    end
  end

  def crumbs(conn, %Photo{} = photo) do
    profile     = conn.assigns[:profile]
    photo_album = conn.assigns[:photo_album]
    content_tag :ol, class: "breadcrumb" do
      [
        content_tag(:li, class: "breadcrumb-item") do
          link(profile.username, to: public_profile_path(conn, :show, profile))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(gettext("Photo Albums"), to: public_profile_photo_album_path(conn, :index, profile))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(photo_album.title, to: public_profile_photo_album_path(conn, :show, profile, photo_album))
        end,
        content_tag(:li, class: "breadcrumb-item") do
          link(photo.title, to: public_profile_photo_album_photo_path(conn, :show, profile, photo_album, photo))
        end,
        content_tag(:li, gettext("Visitors"), class: "breadcrumb-item active")
      ]
    end
  end
end
