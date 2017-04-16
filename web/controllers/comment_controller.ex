defmodule Helheim.CommentController do
  use Helheim.Web, :controller
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.Photo

  def index(conn, %{"profile_id" => user_id} = params), do: index(conn, Repo.get!(User, user_id), params)
  defp index(conn, commentable, params) do
    comments = assoc(commentable, :comments)
               |> Helheim.Comment.newest
               |> preload(:author)
               |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", commentable: commentable, comments: comments)
  end

  def create(conn, %{"blog_post_id" => blog_post_id, "comment" => comment_params}) do
    blog_post = Helheim.BlogPost |> preload(:user) |> Repo.get!(blog_post_id)
    create(conn, blog_post, comment_params, public_profile_blog_post_path(conn, :show, blog_post.user, blog_post))
  end

  def create(conn, %{"profile_id" => profile_id, "comment" => comment_params}) do
    profile = User |> Repo.get!(profile_id)
    create(conn, profile, comment_params, public_profile_comment_path(conn, :index, profile))
  end

  def create(conn, %{"photo_id" => photo_id, "comment" => comment_params}) do
    photo = Photo |> preload(:photo_album) |> Repo.get!(photo_id)
    create(conn, photo, comment_params, public_profile_photo_album_photo_path(conn, :show, photo.photo_album.user_id, photo.photo_album, photo))
  end

  defp create(conn, commentable, comment_params, redirect_to) do
    author = current_resource(conn)
    body   = comment_params["body"]
    result = Helheim.CommentService.create!(commentable, author, body)

    case result do
      {:ok, %{comment: _comment}} ->
        conn
        |> put_flash(:success, gettext("Comment created successfully"))
        |> redirect(to: redirect_to)
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn
        |> put_flash(:error, gettext("Unable to create comment"))
        |> redirect(to: redirect_to)
    end
  end
end
