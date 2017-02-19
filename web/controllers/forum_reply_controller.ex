defmodule Helheim.ForumReplyController do
  use Helheim.Web, :controller
  alias Helheim.Forum
  alias Helheim.ForumReply

  def create(conn, %{"forum_id" => forum_id, "forum_topic_id" => forum_topic_id, "forum_reply" => forum_reply_params}) do
    forum       = Forum |> preload(:forum_category) |> Repo.get!(forum_id)
    forum_topic = assoc(forum, :forum_topics) |> preload(:user) |> Repo.get!(forum_topic_id)
    user        = current_resource(conn)
    changeset   = forum_topic
                  |> Ecto.build_assoc(:forum_replies)
                  |> ForumReply.changeset(forum_reply_params)
                  |> Ecto.Changeset.put_assoc(:user, user)

    case Repo.insert(changeset) do
      {:ok, _forum_reply} ->
        conn
        |> put_flash(:success, gettext("Reply created successfully"))
        |> redirect(to: forum_forum_topic_path(conn, :show, forum, forum_topic))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Reply could not be created"))
        |> redirect(to: forum_forum_topic_path(conn, :show, forum, forum_topic))
    end
  end
end
