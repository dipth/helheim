defmodule Altnation.ProfileCommentController do
  use Altnation.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Altnation.User
  alias Altnation.Comment

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
    author = current_resource(conn)
    profile = Repo.get!(User, profile_id)

    changeset = Comment.changeset(%Comment{}, comment_params)
    |> Ecto.Changeset.put_assoc(:author, author)
    |> Ecto.Changeset.put_assoc(:profile, profile)

    case Repo.insert(changeset) do
      {:ok, _comment} ->
        conn
        |> put_flash(:success, gettext("Comment created successfully"))
        |> redirect(to: public_profile_comment_path(conn, :index, profile))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Unable to create comment"))
        |> redirect(to: public_profile_comment_path(conn, :index, profile))
    end
  end
end
