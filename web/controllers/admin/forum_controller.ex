defmodule Helheim.Admin.ForumController do
  use Helheim.Web, :controller
  alias Helheim.Forum
  alias Helheim.ForumCategory

  def new(conn, %{"forum_category_id" => forum_category_id}) do
    forum_category = Repo.get!(ForumCategory, forum_category_id)
    changeset      = forum_category
                     |> Ecto.build_assoc(:forums)
                     |> Forum.changeset
    render(conn, "new.html", forum_category: forum_category, changeset: changeset)
  end

  def create(conn, %{"forum_category_id" => forum_category_id, "forum" => forum_params}) do
    forum_category = Repo.get!(ForumCategory, forum_category_id)
    changeset      = forum_category
                     |> Ecto.build_assoc(:forums)
                     |> Forum.changeset(forum_params)
    case Repo.insert(changeset) do
      {:ok, _forum} ->
        conn
        |> put_flash(:success, gettext("Forum created successfully."))
        |> redirect(to: admin_forum_category_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", forum_category: forum_category, changeset: changeset)
    end
  end

  def edit(conn, %{"forum_category_id" => forum_category_id, "id" => id}) do
    forum_category = Repo.get!(ForumCategory, forum_category_id)
    forum          = assoc(forum_category, :forums) |> Repo.get!(id)
    changeset      = Forum.changeset(forum)
    render(conn, "edit.html", forum_category: forum_category, forum: forum, changeset: changeset)
  end

  def update(conn, %{"forum_category_id" => forum_category_id, "id" => id, "forum" => forum_params}) do
    forum_category = Repo.get!(ForumCategory, forum_category_id)
    forum          = assoc(forum_category, :forums) |> Repo.get!(id)
    changeset      = Forum.changeset(forum, forum_params)
    case Repo.update(changeset) do
      {:ok, _forum} ->
        conn
        |> put_flash(:success, gettext("Forum updated successfully."))
        |> redirect(to: admin_forum_category_path(conn, :index))
      {:error, changeset} ->
        render(conn, "edit.html", forum_category: forum_category, forum: forum, changeset: changeset)
    end
  end

  def delete(conn, %{"forum_category_id" => forum_category_id, "id" => id}) do
    forum_category = Repo.get!(ForumCategory, forum_category_id)
    forum          = assoc(forum_category, :forums) |> Repo.get!(id)
    Repo.delete!(forum)
    conn
    |> put_flash(:success, gettext("Forum deleted successfully."))
    |> redirect(to: admin_forum_category_path(conn, :index))
  end
end
