defmodule Helheim.ProfileCommentController do
  use Helheim.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Helheim.User
  alias Helheim.Comment
  alias Helheim.ProfileCommentService

  def index(conn, params = %{"profile_id" => user_id}) do
    user = Repo.get!(User, user_id)
    {comments, pagination} =
      assoc(user, :comments)
      |> Comment.newest
      |> Repo.paginate(params)
    comments = Repo.preload(comments, :author)
    render(conn, "index.html", user: user, comments: comments, pagination: pagination)
  end

  def create(conn, %{"profile_id" => profile_id, "comment" => comment_params}) do
    author  = current_resource(conn)
    profile = Repo.get!(User, profile_id)
    result  = ProfileCommentService.insert(comment_params, author, profile)

    case result do
      {:ok, %{comment: _comment}} ->
        conn
        |> put_flash(:success, gettext("Comment created successfully"))
        |> redirect(to: public_profile_comment_path(conn, :index, profile))
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn
        |> put_flash(:error, gettext("Unable to create comment"))
        |> redirect(to: public_profile_comment_path(conn, :index, profile))
    end
  end
end
