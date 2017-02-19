defmodule Helheim.Admin.ForumCategoryController do
  use Helheim.Web, :controller
  alias Helheim.ForumCategory

  def index(conn, _params) do
    forum_categories = ForumCategory |> ForumCategory.in_positional_order |> ForumCategory.with_forums |> Repo.all
    render(conn, "index.html", forum_categories: forum_categories)
  end

  def new(conn, _params) do
    changeset = ForumCategory.changeset(%ForumCategory{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"forum_category" => forum_category_params}) do
    changeset = ForumCategory.changeset(%ForumCategory{}, forum_category_params)
    case Repo.insert(changeset) do
      {:ok, _forum_category} ->
        conn
        |> put_flash(:success, gettext("Forum category created successfully."))
        |> redirect(to: admin_forum_category_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    forum_category = Repo.get!(ForumCategory, id)
    changeset      = ForumCategory.changeset(forum_category)
    render(conn, "edit.html", changeset: changeset, forum_category: forum_category)
  end

  def update(conn, %{"id" => id, "forum_category" => forum_category_params}) do
    forum_category = Repo.get!(ForumCategory, id)
    changeset      = ForumCategory.changeset(forum_category, forum_category_params)
    case Repo.update(changeset) do
      {:ok, _forum_category} ->
        conn
        |> put_flash(:success, gettext("Forum category updated successfully."))
        |> redirect(to: admin_forum_category_path(conn, :index))
      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, forum_category: forum_category)
    end
  end

  def delete(conn, %{"id" => id}) do
    forum_category = Repo.get!(ForumCategory, id)
    Repo.delete!(forum_category)
    conn
    |> put_flash(:success, gettext("Forum category deleted successfully."))
    |> redirect(to: admin_forum_category_path(conn, :index))
  end
end
