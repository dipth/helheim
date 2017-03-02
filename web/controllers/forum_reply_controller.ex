defmodule Helheim.ForumReplyController do
  use Helheim.Web, :controller
  alias Helheim.Forum
  alias Helheim.ForumReply

  plug :find_forum
  plug :find_user
  plug :find_forum_topic
  plug :find_forum_reply when action in [:edit, :update]
  plug :build_edit_changeset when action in [:edit, :update]
  plug :enforce_editable_by when action in [:edit, :update]

  def create(conn, %{"forum_id" => _, "forum_topic_id" => _, "forum_reply" => forum_reply_params}) do
    changeset   = conn.assigns[:forum_topic]
                  |> Ecto.build_assoc(:forum_replies)
                  |> ForumReply.changeset(forum_reply_params)
                  |> Ecto.Changeset.put_assoc(:user, conn.assigns[:user])

    case Repo.insert(changeset) do
      {:ok, _forum_reply} ->
        conn
        |> put_flash(:success, gettext("Reply created successfully"))
        |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], conn.assigns[:forum_topic]))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Reply could not be created"))
        |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], conn.assigns[:forum_topic]))
    end
  end

  def edit(conn, %{"forum_id" => _, "forum_topic_id" => _, "id" => _}) do
    render(conn, "edit.html")
  end

  def update(conn, %{"forum_id" => _, "forum_topic_id" => _, "id" => _, "forum_reply" => _}) do
    case Repo.update(conn.assigns[:changeset]) do
      {:ok, _forum_reply} ->
        conn
        |> put_flash(:success, gettext("Forum reply updated successfully."))
        |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], conn.assigns[:forum_topic]))
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
                  |> Repo.get!(conn.params["forum_topic_id"])
    assign conn, :forum_topic, forum_topic
  end

  defp find_forum_reply(conn, _) do
    forum_reply = assoc(conn.assigns[:forum_topic], :forum_replies)
                  |> preload(:user)
                  |> Repo.get!(conn.params["id"])
    assign conn, :forum_reply, forum_reply
  end

  defp enforce_editable_by(conn, _) do
    unless ForumReply.editable_by?(conn.assigns[:forum_reply], conn.assigns[:user]) do
      conn
      |> put_flash(:error, gettext("You can only edit a forum reply in the first 10 minutes!"))
      |> redirect(to: forum_forum_topic_path(conn, :show, conn.assigns[:forum], conn.assigns[:forum_topic]))
      |> halt
    else
      conn
    end
  end

  defp build_edit_changeset(conn, _) do
    forum_reply_params = conn.params["forum_reply"] || %{}
    changeset = conn.assigns[:forum_reply]
                |> ForumReply.changeset(forum_reply_params)
    assign conn, :changeset, changeset
  end
end
