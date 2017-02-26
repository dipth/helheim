defmodule Helheim.ForumTopicController do
  use Helheim.Web, :controller
  alias Helheim.Forum
  alias Helheim.ForumTopic
  alias Helheim.ForumReply

  plug :find_forum
  plug :find_user
  plug :enforce_locked_forum when not action in [:show]
  plug :build_forum_topic_changeset when not action in [:show]

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

  def show(conn, %{"forum_id" => _, "id" => id} = params) do
    forum_topic   = assoc(conn.assigns[:forum], :forum_topics) |> preload(:user) |> Repo.get!(id)
    forum_replies = assoc(forum_topic, :forum_replies)
                    |> preload(:user)
                    |> Repo.paginate(page: sanitized_page(params["page"]))
    changeset     = forum_topic
                    |> Ecto.build_assoc(:forum_replies)
                    |> ForumReply.changeset()
                    |> Ecto.Changeset.put_assoc(:user, conn.assigns[:user])
    render(conn, "show.html", forum_topic: forum_topic, forum_replies: forum_replies, changeset: changeset)
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

  defp build_forum_topic_changeset(conn, _) do
    forum_topic_params = conn.params["forum_topic"] || %{}
    changeset = conn.assigns[:forum]
                |> Ecto.build_assoc(:forum_topics)
                |> ForumTopic.changeset(forum_topic_params)
                |> Ecto.Changeset.put_assoc(:user, conn.assigns[:user])
    assign conn, :changeset, changeset
  end
end
