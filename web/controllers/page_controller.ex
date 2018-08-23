defmodule Helheim.PageController do
  use Helheim.Web, :controller
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Term
  alias Helheim.CalendarEvent

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

  def front_page(conn, _params) do
    newest_users =
      User
      |> User.recently_logged_in
      |> User.with_avatar
      |> limit(140)
      |> Repo.all

    newest_blog_posts =
      BlogPost.newest_for_frontpage(current_resource(conn), 8)
      |> preload(:user)
      |> Repo.all

    newest_forum_topics =
      ForumTopic.newest_for_frontpage(12)
      |> ForumTopic.with_latest_reply
      |> Repo.all

    upcoming_events =
      CalendarEvent
      |> CalendarEvent.approved()
      |> CalendarEvent.upcoming()
      |> CalendarEvent.chronological()
      |> limit(4)
      |> Repo.all

    newest_photos =
      Helheim.Photo.newest_for_frontpage(current_resource(conn), 24)

    render conn, "front_page.html",
      newest_users: newest_users,
      newest_blog_posts: newest_blog_posts,
      newest_photos: newest_photos,
      newest_forum_topics: newest_forum_topics,
      upcoming_events: upcoming_events
  end

  def terms(conn, _params) do
    term = Term |> Term.newest |> Term.published |> Ecto.Query.first |> Repo.one
    render(conn, "terms.html", term: term, layout: {Helheim.LayoutView, "app_special.html"})
  end

  def banned(conn, _params) do
    render(conn, "banned.html", layout: {Helheim.LayoutView, "app_special.html"})
  end

  def debug(conn, _params) do
    user = Repo.one(from x in User, order_by: [desc: x.id], limit: 1)
    render conn, "debug.html", user: user, layout: {Helheim.LayoutView, "app_special.html"}
  end
end
