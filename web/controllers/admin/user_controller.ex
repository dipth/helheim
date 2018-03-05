defmodule Helheim.Admin.UserController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Comment
  alias Helheim.ForumTopic
  alias Helheim.ForumReply
  alias Helheim.Photo

  def index(conn, params) do
    search    = params["search"] || %{}
    sort      = params["sort"] || "username"
    direction = params["direction"] || "asc"
    page      = sanitized_page(params["page"])

    users = User
            |> User.search_as_admin(search)
            |> User.sort(sort, direction)
            |> Repo.paginate(page: page)
    
    render conn, "index.html", users: users
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    render conn, "show.html",
      user: user,
      potential_alts:
      potential_alts(user),
      recent_blog_posts: recent_blog_posts(user),
      recent_comments: recent_comments(user),
      recent_forum_topics: recent_forum_topics(user),
      recent_forum_replies: recent_forum_replies(user),
      recent_photos: recent_photos(user)
  end

  defp potential_alts(user) do
    User
    |> User.search_by_last_and_previous_ip(user.last_login_ip, user.previous_login_ip)
    |> where([u], u.id != ^user.id)
    |> Repo.all
  end

  defp recent_blog_posts(user) do
    assoc(user, :blog_posts)
    |> BlogPost.published
    |> BlogPost.newest
    |> BlogPost.not_private
    |> limit(5)
    |> preload(:user)
    |> Repo.all
  end

  defp recent_comments(user) do
    assoc(user, :authored_comments)
    |> Comment.newest
    |> Comment.not_deleted
    |> Comment.with_preloads
    |> limit(5)
    |> Repo.all
  end

  defp recent_forum_topics(user) do
    assoc(user, :forum_topics)
    |> ForumTopic.newest
    |> limit(5)
    |> Repo.all
  end

  defp recent_forum_replies(user) do
    assoc(user, :forum_replies)
    |> ForumReply.newest
    |> limit(5)
    |> preload(:forum_topic)
    |> Repo.all
  end

  defp recent_photos(user) do
    Photo
    |> Photo.by(user)
    |> Photo.newest
    |> Photo.not_private
    |> preload(:photo_album)
    |> limit(5)
    |> Repo.all
  end
end
