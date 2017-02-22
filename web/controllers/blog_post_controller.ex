defmodule Helheim.BlogPostController do
  use Helheim.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Helheim.BlogPost
  alias Helheim.User
  alias Helheim.Comment

  def index(conn, params = %{"profile_id" => user_id}) do
    user = Repo.get!(User, user_id)
    blog_posts =
      assoc(user, :blog_posts)
      |> BlogPost.newest
      |> preload(:user)
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", blog_posts: blog_posts)
  end

  def new(conn, _params) do
    user = current_resource(conn)
    changeset =
      user
        |> Ecto.build_assoc(:blog_posts)
        |> BlogPost.changeset(%{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"blog_post" => blog_post_params}) do
    user = current_resource(conn)
    changeset =
      user
        |> Ecto.build_assoc(:blog_posts)
        |> BlogPost.changeset(blog_post_params)

    case Repo.insert(changeset) do
      {:ok, blog_post} ->
        conn
        |> put_flash(:success, gettext("Blog post created successfully."))
        |> redirect(to: public_profile_blog_post_path(conn, :show, user, blog_post))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, params = %{"profile_id" => user_id, "id" => id}) do
    user = Repo.get!(User, user_id)
    blog_post =
      assoc(user, :blog_posts)
      |> Repo.get!(id)
      |> Repo.preload(:user)
    comments =
      assoc(blog_post, :comments)
      |> Comment.newest
      |> preload(:author)
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "show.html", blog_post: blog_post, comments: comments)
  end

  def edit(conn, %{"id" => id}) do
    user = current_resource(conn)
    blog_post = assoc(user, :blog_posts) |> Repo.get!(id)
    changeset = BlogPost.changeset(blog_post)
    render(conn, "edit.html", blog_post: blog_post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "blog_post" => blog_post_params}) do
    user = current_resource(conn)
    blog_post = assoc(user, :blog_posts) |> Repo.get!(id)
    changeset = BlogPost.changeset(blog_post, blog_post_params)

    case Repo.update(changeset) do
      {:ok, blog_post} ->
        conn
        |> put_flash(:success, gettext("Blog post updated successfully."))
        |> redirect(to: public_profile_blog_post_path(conn, :show, user, blog_post))
      {:error, changeset} ->
        render(conn, "edit.html", blog_post: blog_post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = current_resource(conn)
    blog_post = assoc(user, :blog_posts) |> Repo.get!(id)
    Repo.delete!(blog_post)

    conn
    |> put_flash(:success, gettext("Blog post deleted successfully."))
    |> redirect(to: public_profile_blog_post_path(conn, :index, user))
  end
end
