defmodule HelheimWeb.ForumReplyController do
  use HelheimWeb, :controller
  alias Helheim.Forum
  alias Helheim.ForumReply
  alias Helheim.ForumTopic

  plug :find_forum
  plug :find_user
  plug :find_forum_topic
  plug :enforce_lock when action in [:create]
  plug :find_forum_reply when action in [:edit, :update]
  plug :build_edit_changeset when action in [:edit, :update]
  plug :enforce_editable_by when action in [:edit, :update]

  def create(conn, %{"forum_id" => _, "forum_topic_id" => _, "forum_reply" => forum_reply_params}) do
    user   = current_resource(conn)
    body   = forum_reply_params["body"]
    result = Helheim.ForumReplyService.create!(conn.assigns[:forum_topic], user, body)

    case result do
      {:ok, %{forum_reply: _forum_reply}} ->
        conn
        |> put_flash(:success, gettext("Reply created successfully"))
        |> redirect(to: "#{forum_forum_topic_path(conn, :show, conn.assigns[:forum], conn.assigns[:forum_topic], page: "last")}#reply")
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
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

  defp enforce_lock(conn, _) do
    if ForumTopic.locked?(conn.assigns[:forum_topic]) do
      conn
      |> put_status(:not_found)
      |> halt()
    else
      conn
    end
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
      |> put_flash(:error, gettext("You can only edit a forum reply in the first %{minutes} minutes!", minutes: ForumReply.edit_timelimit_in_minutes))
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
