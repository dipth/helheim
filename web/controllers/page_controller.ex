defmodule Helheim.PageController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.BlogPost

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
      |> limit(10)
      |> Helheim.Repo.all

    newest_blog_posts =
      BlogPost
      |> BlogPost.newest
      |> limit(5)
      |> Helheim.Repo.all
      |> Repo.preload(:user)

    render conn, "front_page.html",
      newest_users: newest_users,
      newest_blog_posts: newest_blog_posts
  end

  def debug(conn, _params) do
    user = Repo.one(from x in User, order_by: [desc: x.id], limit: 1)
    render conn, "debug.html", user: user, layout: {Helheim.LayoutView, "app_special.html"}
  end
end
