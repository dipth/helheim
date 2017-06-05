defmodule Helheim.CommentController do
  use Helheim.Web, :controller
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.Photo
  alias Helheim.Comment

  plug :find_commentable when action in [:index, :create]
  plug Helheim.Plug.EnforceBlock when action in [:index, :create]

  def index(conn, params) do
    comments = assoc(conn.assigns[:commentable], :comments)
               |> Comment.not_deleted
               |> Comment.newest
               |> Comment.with_preloads
               |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", commentable: conn.assigns[:commentable], comments: comments)
  end

  def create(conn, %{"comment" => comment_params}) do
    author = current_resource(conn)
    body   = comment_params["body"]
    result = Helheim.CommentService.create!(conn.assigns[:commentable], author, body)

    case result do
      {:ok, %{comment: _comment}} ->
        conn
        |> put_flash(:success, gettext("Comment created successfully"))
        |> redirect(to: conn.assigns[:redirect_to])
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn
        |> put_flash(:error, gettext("Unable to create comment"))
        |> redirect(to: conn.assigns[:redirect_to])
    end
  end

  def delete(conn, %{"id" => id}) do
    comment = Comment |> Comment.with_preloads() |> Repo.get!(id)
    case Helheim.CommentService.delete!(comment, current_resource(conn)) do
      {:ok, %{comment: _}} ->
        render(conn, "delete.js", comment: comment)
      {:error, _, _, _} ->
        send_resp(conn, 401, "")
    end
  end

  defp find_commentable(conn, _) do
    assign_commentable(conn, conn.params)
  end

  defp assign_commentable(conn, %{"profile_id" => user_id}) do
    user = Repo.get!(User, user_id)
    conn
    |> assign(:user, user) # For blocking
    |> assign(:commentable, user)
    |> assign(:redirect_to, public_profile_comment_path(conn, :index, user))
  end

  defp assign_commentable(conn, %{"blog_post_id" => blog_post_id}) do
    blog_post = Helheim.BlogPost |> preload(:user) |> Repo.get!(blog_post_id)
    conn
    |> assign(:user, blog_post.user) # For blocking
    |> assign(:commentable, blog_post)
    |> assign(:redirect_to, public_profile_blog_post_path(conn, :show, blog_post.user, blog_post))
  end

  defp assign_commentable(conn, %{"photo_id" => photo_id}) do
    photo = Photo |> preload(photo_album: :user) |> Repo.get!(photo_id)
    conn
    |> assign(:user, photo.photo_album.user) # For blocking
    |> assign(:commentable, photo)
    |> assign(:redirect_to, public_profile_photo_album_photo_path(conn, :show, photo.photo_album.user, photo.photo_album, photo))
  end
end
