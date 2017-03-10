defmodule Helheim.ForumTopicController do
  use Helheim.Web, :controller
  alias Helheim.Forum
  alias Helheim.ForumTopic
  alias Helheim.ForumReply

  plug :find_forum
  plug :find_user
  plug :find_forum_topic when action in [:show, :edit, :update]
  plug :enforce_locked_forum when action in [:new, :create]
  plug :build_new_forum_topic_changeset when action in [:new, :create]
  plug :build_edit_forum_topic_changeset when action in [:edit, :update]
  plug :enforce_editable_by when action in [:edit, :update]

  def new(conn, %{"forum_id" => _}) do
    render(conn, "new.html")
  end

  def create(conn, %{"forum_id" => _, "forum_topic" => _}) do
    case Repo.insert(conn.assigns[:changeset]) do
      {:ok, forum_topic} ->
        conn
        |> put_flash(:success, gettext("Forum topic created successfully."))
        |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], forum_topic))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"forum_id" => _, "id" => _} = params) do
    forum_replies = assoc(conn.assigns[:forum_topic], :forum_replies)
                    |> ForumReply.in_order
                    |> preload(:user)
                    |> Repo.paginate(page: sanitized_page(params["page"]))
    changeset     = conn.assigns[:forum_topic]
                    |> Ecto.build_assoc(:forum_replies)
                    |> ForumReply.changeset()
                    |> Ecto.Changeset.put_assoc(:user, conn.assigns[:user])
    render(conn, "show.html", forum_replies: forum_replies, changeset: changeset)
  end

  def edit(conn, %{"forum_id" => _, "id" => _}) do
    render(conn, "edit.html")
  end

  def update(conn, %{"forum_id" => _, "id" => _, "forum_topic" => _}) do
    case Repo.update(conn.assigns[:changeset]) do
      {:ok, forum_topic} ->
        conn
        |> put_flash(:success, gettext("Forum topic updated successfully."))
        |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], forum_topic))
      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp find_forum(conn, _) do
    forum_id = conn.params["forum_id"]
    forum    = Forum |> preload(:forum_category) |> Repo.get!(forum_id)
    assign conn, :forum, forum
  end

  defp find_user(conn, _) do
    user = current_resource(conn)
    assign conn, :user, user
  end

  defp find_forum_topic(conn, _) do
    forum_topic = assoc(conn.assigns[:forum], :forum_topics)
                  |> preload(:user)
                  |> Repo.get!(conn.params["id"])
    assign conn, :forum_topic, forum_topic
  end

  defp enforce_locked_forum(conn, _) do
    if Forum.locked_for?(conn.assigns[:forum], conn.assigns[:user]) do
      conn
      |> put_flash(:error, gettext("You cannot create a topic in a locked forum!"))
      |> redirect(to: forum_path(conn, :show, conn.assigns[:forum]))
      |> halt
    else
      conn
    end
  end

  defp enforce_editable_by(conn, _) do
    unless ForumTopic.editable_by?(conn.assigns[:forum_topic], conn.assigns[:user]) do
      conn
      |> put_flash(:error, gettext("You can only edit a forum topic in the first 10 minutes!"))
      |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], conn.assigns[:forum_topic]))
      |> halt
    else
      conn
    end
  end

  defp build_new_forum_topic_changeset(conn, _) do
    forum_topic_params = conn.params["forum_topic"] || %{}
    changeset = conn.assigns[:forum]
                |> Ecto.build_assoc(:forum_topics)
                |> ForumTopic.changeset(forum_topic_params)
                |> Ecto.Changeset.put_assoc(:user, conn.assigns[:user])
    assign conn, :changeset, changeset
  end

  defp build_edit_forum_topic_changeset(conn, _) do
    forum_topic_params = conn.params["forum_topic"] || %{}
    changeset = conn.assigns[:forum_topic]
                |> ForumTopic.changeset(forum_topic_params)
    assign conn, :changeset, changeset
  end
end
