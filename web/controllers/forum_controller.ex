defmodule Helheim.ForumController do
  use Helheim.Web, :controller
  alias Helheim.ForumCategory
  alias Helheim.Forum
  alias Helheim.ForumTopic

  def index(conn, _params) do
    forum_categories = ForumCategory
                       |> ForumCategory.in_positional_order
                       |> ForumCategory.with_forums_and_latest_topic
                       |> Repo.all

    render(conn, "index.html", forum_categories: forum_categories)
  end

  def show(conn, %{"id" => id} = params) do
    forum = Forum |> preload(:forum_category) |> Repo.get!(id)
    forum_topics = assoc(forum, :forum_topics)
                   |> ForumTopic.with_latest_reply
                   |> ForumTopic.in_order
                   |> preload(:user)
                   |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "show.html", forum: forum, forum_topics: forum_topics)
  end
end
