defmodule Helheim.ProfileController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Comment
  alias Helheim.Photo

  def show(conn, params) do
    user = if params["id"] do
      Repo.get!(User, params["id"])
    else
      Guardian.Plug.current_resource(conn)
    end

    newest_blog_posts =
      assoc(user, :blog_posts)
      |> BlogPost.newest
      |> limit(5)
      |> Helheim.Repo.all
      |> Repo.preload(:user)
    newest_comments =
      assoc(user, :comments)
      |> Comment.newest
      |> limit(5)
      |> Helheim.Repo.all
      |> Repo.preload(:author)
    newest_photos = Photo.newest_public_photos_by(user, 5)

    render conn, "show.html", user: user, newest_blog_posts: newest_blog_posts, newest_comments: newest_comments, newest_photos: newest_photos
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
        |> redirect(to: page_path(conn, :front_page))
      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end
end
