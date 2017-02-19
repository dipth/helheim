defmodule Helheim.ForumTopicController do
  use Helheim.Web, :controller
  alias Helheim.Forum
  alias Helheim.ForumTopic
  alias Helheim.ForumReply

  def new(conn, %{"forum_id" => forum_id}) do
    forum     = Forum |> preload(:forum_category) |> Repo.get!(forum_id)
    user      = current_resource(conn)
    changeset = forum
                |> Ecto.build_assoc(:forum_topics)
                |> ForumTopic.changeset
                |> Ecto.Changeset.put_assoc(:user, user)
    render(conn, "new.html", forum: forum, changeset: changeset)
  end

  def create(conn, %{"forum_id" => forum_id, "forum_topic" => forum_topic_params}) do
    forum     = Forum |> preload(:forum_category) |> Repo.get!(forum_id)
    user      = current_resource(conn)
    changeset = forum
                |> Ecto.build_assoc(:forum_topics)
                |> ForumTopic.changeset(forum_topic_params)
                |> Ecto.Changeset.put_assoc(:user, user)

    case Repo.insert(changeset) do
      {:ok, forum_topic} ->
        conn
        |> put_flash(:success, gettext("Forum topic created successfully."))
        |> redirect(to: forum_forum_topic_path(conn, :show, forum, forum_topic))
      {:error, changeset} ->
        render(conn, "new.html", forum: forum, changeset: changeset)
    end
  end

  def show(conn, %{"forum_id" => forum_id, "id" => id} = params) do
    forum         = Forum |> preload(:forum_category) |> Repo.get!(forum_id)
    forum_topic   = assoc(forum, :forum_topics) |> preload(:user) |> Repo.get!(id)
    forum_replies = assoc(forum_topic, :forum_replies)
                    |> preload(:user)
                    |> Repo.paginate(page: sanitized_page(params["page"]))
    user      = current_resource(conn)
    changeset = forum_topic
                |> Ecto.build_assoc(:forum_replies)
                |> ForumReply.changeset()
                |> Ecto.Changeset.put_assoc(:user, user)
    render(conn, "show.html", forum: forum, forum_topic: forum_topic, forum_replies: forum_replies, changeset: changeset)
  end
end
