defmodule Helheim.CommentView do
  use Helheim.Web, :view
  alias Helheim.User
  alias Helheim.BlogPost

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
end
