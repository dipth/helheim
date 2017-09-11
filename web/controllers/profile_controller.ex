defmodule Helheim.ProfileController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Comment
  alias Helheim.Photo
  alias Helheim.ForumTopic

  plug :find_user when action in [:show]
  plug Helheim.Plug.EnforceBlock when action in [:show]

  def index(conn, params) do
    search  = params["search"] || %{}
    sorting = search["sorting"] || "creation"
    users = User
            |> User.confirmed
            |> User.search(search)
            |> User.sort(sorting)
            |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", users: users)
  end

  def show(conn, _) do
    user = conn.assigns[:user]

    newest_blog_posts =
      assoc(user, :blog_posts)
      |> BlogPost.published
      |> BlogPost.newest
      |> limit(4)
      |> Helheim.Repo.all
      |> Repo.preload(:user)
    newest_comments =
      assoc(user, :comments)
      |> Comment.not_deleted
      |> Comment.newest
      |> limit(5)
      |> Comment.with_preloads
      |> Helheim.Repo.all
    newest_forum_topics = ForumTopic
      |> where(user_id: ^user.id)
      |> ForumTopic.with_latest_reply
      |> order_by([desc: :updated_at])
      |> preload([:forum, :user])
      |> limit(6)
      |> Repo.all
    newest_photos = Photo.newest_public_photos_by(user, 5)

    Helheim.VisitorLogEntry.track! current_resource(conn), user

    render conn, "show.html",
      user: user,
      newest_blog_posts: newest_blog_posts,
      newest_comments: newest_comments,
      newest_photos: newest_photos,
      newest_forum_topics: newest_forum_topics
  end

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.profile_changeset(user)
    render conn, "edit.html", changeset: changeset
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.profile_changeset(user, user_params)
    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, gettext("Profile updated!"))
        |> redirect(to: public_profile_path(conn, :show, user))
      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  defp find_user(conn, _) do
    user = if conn.params["id"] do
      Repo.get!(User, conn.params["id"])
    else
      Guardian.Plug.current_resource(conn)
    end

    assign conn, :user, user
  end
end
