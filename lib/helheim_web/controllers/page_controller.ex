defmodule HelheimWeb.PageController do
  use HelheimWeb, :controller
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Term
  alias Helheim.CalendarEvent
  alias Helheim.SongListen
  alias Helheim.Music.Charts

  def index(conn, _params) do
    if Guardian.Plug.current_resource(conn) do
      conn |> redirect(to: page_path(conn, :front_page))
    else
      render conn, "index.html", layout: {HelheimWeb.LayoutView, "app_special.html"}
    end
  end

  def confirmation_pending(conn, _params) do
    render conn, "confirmation_pending.html", layout: {HelheimWeb.LayoutView, "app_special.html"}
  end

  def front_page(conn, _params) do
    newest_users =
      User
      |> User.recently_logged_in
      |> User.with_avatar
      |> User.without_ids(conn.assigns[:ignoree_ids])
      |> limit(140)
      |> Repo.all

    newest_blog_posts =
      BlogPost.newest_for_frontpage(current_resource(conn), 8, conn.assigns[:ignoree_ids])
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
      |> limit(5)
      |> Repo.all

    newest_photos =
      Helheim.Photo.newest_for_frontpage(current_resource(conn), 24, conn.assigns[:ignoree_ids])

    recent_song_listens =
      SongListen
      |> SongListen.not_from_users(conn.assigns[:ignoree_ids])
      |> SongListen.newest
      |> SongListen.with_preloads
      |> limit(10)
      |> Repo.all

    render conn, "front_page.html",
      newest_users: newest_users,
      newest_blog_posts: newest_blog_posts,
      newest_photos: newest_photos,
      newest_forum_topics: newest_forum_topics,
      upcoming_events: upcoming_events,
      recent_song_listens: recent_song_listens,
      top_songs_today: Charts.top_songs_today(5, conn.assigns[:ignoree_ids]),
      top_songs_week: Charts.top_songs_this_week(5, conn.assigns[:ignoree_ids])
  end

  def terms(conn, _params) do
    term = Term |> Term.newest |> Term.published |> Ecto.Query.first |> Repo.one
    render(conn, "terms.html", term: term, layout: {HelheimWeb.LayoutView, "app_special.html"})
  end

  def staff(conn, _params) do
    admins = User |> User.admins() |> User.sort("username") |> Repo.all
    mods   = User |> User.mods() |> User.sort("username") |> Repo.all
    render(conn, "staff.html", admins: admins, mods: mods)
  end

  def banned(conn, _params) do
    render(conn, "banned.html", layout: {HelheimWeb.LayoutView, "app_special.html"})
  end

  def debug(conn, _params) do
    user = Repo.one(from x in User, order_by: [desc: x.id], limit: 1)
    render conn, "debug.html", user: user, layout: {HelheimWeb.LayoutView, "app_special.html"}
  end
end
