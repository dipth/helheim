defmodule HelheimWeb.BlogPostController do
  use HelheimWeb, :controller
  alias Helheim.BlogPost
  alias Helheim.User
  alias Helheim.Comment
  alias Helheim.BlogPostService

  plug :find_user when action in [:index, :show]
  plug HelheimWeb.Plug.EnforceBlock when action in [:index, :show]

  def index(conn, params = %{"profile_id" => _}) do
    user = conn.assigns[:user]
    blog_posts =
      assoc(user, :blog_posts)
      |> BlogPost.published_by_owner(user, current_resource(conn))
      |> BlogPost.newest
      |> BlogPost.visible_by(current_resource(conn))
      |> preload(:user)
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", user: user, blog_posts: blog_posts)
  end

  def index(conn, params) do
    blog_posts =
      BlogPost
      |> BlogPost.published
      |> BlogPost.newest
      |> BlogPost.visible_by(current_resource(conn))
      |> BlogPost.not_from_ignoree(conn.assigns[:ignoree_ids])
      |> BlogPost.not_private
      |> preload(:user)
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index_all_public.html", blog_posts: blog_posts)
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

    case BlogPostService.create!(user, blog_post_params) do
      {:ok, blog_post} ->
        conn
        |> put_flash(:success, gettext("Blog post created successfully."))
        |> redirect(to: public_profile_blog_post_path(conn, :show, user, blog_post))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, params = %{"profile_id" => _, "id" => id}) do
    user = conn.assigns[:user]
    blog_post =
      assoc(user, :blog_posts)
      |> BlogPost.published_by_owner(user, current_resource(conn))
      |> BlogPost.visible_by(current_resource(conn))
      |> Repo.get!(id)
      |> Repo.preload(:user)
    comments =
      assoc(blog_post, :comments)
      |> Comment.not_deleted
      |> Comment.newest
      |> Comment.with_preloads
      |> Repo.paginate(page: sanitized_page(params["page"]))
    Helheim.VisitorLogEntry.track! current_resource(conn), blog_post
    render(conn, "show.html", user: user, blog_post: blog_post, comments: comments)
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

  defp find_user(conn, _) do
    assign_user(conn, conn.params)
  end

  defp assign_user(conn, %{"profile_id" => profile_id}) do
    conn
    |> assign(:user, Repo.get!(User, profile_id))
  end
  defp assign_user(conn, _), do: conn
end
