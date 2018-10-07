defmodule HelheimWeb.CommentView do
  use HelheimWeb, :view
  alias Helheim.Comment
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Photo
  alias Helheim.CalendarEvent

  def crumbs(conn, %User{} = profile) do
    content_tag :ol, class: "breadcrumb" do
      [
        content_tag(:li, class: "breadcrumb-item") do
          link(profile.username, to: public_profile_path(conn, :show, profile))
        end,
        content_tag(:li, gettext("Guest Book"), class: "breadcrumb-item active")
      ]
    end
  end

  def index_title(%User{}, true), do: gettext("Newest Guest Book Entries")
  def index_title(%User{}, false), do: gettext("Guest Book Entries")
  def index_title(_, _), do: gettext("Comments")

  def show_all_path(conn, %User{} = profile), do: public_profile_comment_path(conn, :index, profile)

  def post_path(conn, %User{} = profile), do: public_profile_comment_path(conn, :create, profile)
  def post_path(conn, %BlogPost{} = blog_post), do: blog_post_comment_path(conn, :create, blog_post)
  def post_path(conn, %Photo{} = photo), do: photo_album_photo_comment_path(conn, :create, photo.photo_album_id, photo)
  def post_path(conn, %CalendarEvent{} = calendar_event), do: calendar_event_comment_path(conn, :create, calendar_event)

  def edit_path(conn, comment, %User{} = profile), do: public_profile_comment_path(conn, :edit, profile, comment)
  def edit_path(conn, comment, %BlogPost{} = blog_post), do: blog_post_comment_path(conn, :edit, blog_post, comment)
  def edit_path(conn, comment, %Photo{} = photo), do: photo_album_photo_comment_path(conn, :edit, photo.photo_album_id, photo, comment)
  def edit_path(conn, comment, %CalendarEvent{} = calendar_event), do: calendar_event_comment_path(conn, :edit, calendar_event, comment)

  def patch_path(conn, comment, %User{} = profile), do: public_profile_comment_path(conn, :update, profile, comment)
  def patch_path(conn, comment, %BlogPost{} = blog_post), do: blog_post_comment_path(conn, :update, blog_post, comment)
  def patch_path(conn, comment, %Photo{} = photo), do: photo_album_photo_comment_path(conn, :update, photo.photo_album_id, photo, comment)
  def patch_path(conn, comment, %CalendarEvent{} = calendar_event), do: calendar_event_comment_path(conn, :update, calendar_event, comment)

  def commentable_link(conn, %User{} = profile), do: link(commentable_link_title(profile), to: public_profile_comment_path(conn, :index, profile))
  def commentable_link(conn, %BlogPost{} = blog_post), do: link(commentable_link_title(blog_post), to: public_profile_blog_post_path(conn, :show, blog_post.user_id, blog_post))
  def commentable_link(conn, %Photo{} = photo), do: link(commentable_link_title(photo), to: public_profile_photo_album_photo_path(conn, :show, photo.photo_album.user_id, photo.photo_album_id, photo))
  def commentable_link(conn, %CalendarEvent{} = calendar_event), do: link(commentable_link_title(calendar_event), to: calendar_event_path(conn, :show, calendar_event))

  def commentable_link_title(%User{} = profile), do: "#{gettext("Profile")}: #{profile.username}"
  def commentable_link_title(%BlogPost{} = blog_post), do: "#{gettext("Blog Post")}: #{blog_post.title}"
  def commentable_link_title(%Photo{} = photo), do: "#{gettext("Photo")}: #{photo.title}"
  def commentable_link_title(%CalendarEvent{} = calendar_event), do: "#{gettext("Event")}: #{calendar_event.title}"

  def render_comments(conn, comments, commentable, opts \\ []) do
    opts = Keyword.merge(
      [
        conn:        conn,
        comments:    comments,
        commentable: commentable,
        limited:     false,
        post_path:   post_path(conn, commentable)
      ],
      opts
    )

    render("comments.html", opts)
  end

  def delete_comment_button(conn, comment) do
    cond do
      Comment.deletable_by?(comment, current_resource(conn)) ->
        css_class      = "btn btn-link btn-danger btn-sm popover-confirmable"
        label          = gettext("Delete")
        question_label = gettext("Are you sure you want to delete this comment?")
        submit_label   = gettext("Delete")
        cancel_label   = gettext("Cancel")
        submit_path    = comment_path(conn, :delete, comment)
        submit_type    = "DELETE"

        link(to: "#", class: css_class, data: ["question-label": question_label, "submit-label": submit_label, "cancel-label": cancel_label, "submit-path": submit_path, "submit-type": submit_type]) do
          [
            content_tag(:i, "", class: "fa fa-trash"),
            " ",
            label
          ]
        end
      true -> ""
    end
  end
end
