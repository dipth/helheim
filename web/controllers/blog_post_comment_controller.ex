defmodule Helheim.BlogPostCommentController do
  use Helheim.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Helheim.BlogPost
  alias Helheim.BlogPostCommentService

  def create(conn, %{"blog_post_id" => blog_post_id, "comment" => comment_params}) do
    author    = current_resource(conn)
    blog_post = Repo.get!(BlogPost, blog_post_id) |> Repo.preload(:user)
    result    = BlogPostCommentService.insert(comment_params, author, blog_post)

    case result do
      {:ok, %{comment: _comment}} ->
        conn
        |> put_flash(:success, gettext("Comment created successfully"))
        |> redirect(to: public_profile_blog_post_path(conn, :show, blog_post.user, blog_post))
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn
        |> put_flash(:error, gettext("Unable to create comment"))
        |> redirect(to: public_profile_blog_post_path(conn, :show, blog_post.user, blog_post))
    end
  end
end
