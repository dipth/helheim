defmodule Helheim.PageController do
  use Helheim.Web, :controller
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Term

  def index(conn, _params) do
    if Guardian.Plug.current_resource(conn) do
      conn |> redirect(to: page_path(conn, :front_page))
    else
      render conn, "index.html", layout: {Helheim.LayoutView, "app_special.html"}
    end
  end

  def confirmation_pending(conn, _params) do
    render conn, "confirmation_pending.html", layout: {Helheim.LayoutView, "app_special.html"}
  end

  def signed_in(conn, _params) do
    render conn, "signed_in.html", layout: {Helheim.LayoutView, "app_special.html"}
  end

  def front_page(conn, _params) do
    newest_users =
      User
      |> User.newest
      |> User.with_avatar
      |> limit(40)
      |> Helheim.Repo.all

    newest_blog_posts =
      BlogPost
      |> BlogPost.newest
      |> limit(5)
      |> preload(:user)
      |> Helheim.Repo.all

    newest_forum_topics = ForumTopic
      |> ForumTopic.with_latest_reply
      |> order_by([desc: :updated_at])
      |> preload([:forum, :user])
      |> limit(6)
      |> Repo.all

    newest_photos = Helheim.Photo.newest_public_photos(15)

    render conn, "front_page.html",
      newest_users: newest_users,
      newest_blog_posts: newest_blog_posts,
      newest_photos: newest_photos,
      newest_forum_topics: newest_forum_topics
  end

  def terms(conn, _params) do
    term = Term |> Term.newest |> Term.published |> Ecto.Query.first |> Repo.one
    render(conn, "terms.html", term: term, layout: {Helheim.LayoutView, "app_special.html"})
  end

  def debug(conn, _params) do
    user = Repo.one(from x in User, order_by: [desc: x.id], limit: 1)
    render conn, "debug.html", user: user, layout: {Helheim.LayoutView, "app_special.html"}
  end
end
