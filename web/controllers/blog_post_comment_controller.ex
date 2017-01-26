defmodule Altnation.BlogPostCommentController do
  use Altnation.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Altnation.BlogPost
  alias Altnation.Comment

  def create(conn, %{"blog_post_id" => blog_post_id, "comment" => comment_params}) do
    author = current_resource(conn)
    blog_post = Repo.get!(BlogPost, blog_post_id) |> Repo.preload(:user)

    changeset = Comment.changeset(%Comment{}, comment_params)
    |> Ecto.Changeset.put_assoc(:author, author)
    |> Ecto.Changeset.put_assoc(:blog_post, blog_post)

    case Repo.insert(changeset) do
      {:ok, _comment} ->
        conn
        |> put_flash(:success, gettext("Comment created successfully"))
        |> redirect(to: public_profile_blog_post_path(conn, :show, blog_post.user, blog_post))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Unable to create comment"))
        |> redirect(to: public_profile_blog_post_path(conn, :show, blog_post.user, blog_post))
    end
  end
end
