defmodule Helheim.VisitorLogEntryController do
  use Helheim.Web, :controller
  alias Helheim.VisitorLogEntry
  alias Helheim.User

  def index(conn, %{"profile_id" => profile_id, "blog_post_id" => blog_post_id} = params) do
    profile   = Repo.get!(User, profile_id)
    blog_post = assoc(profile, :blog_posts) |> Repo.get!(blog_post_id)
    entries   = find_entries(blog_post, params)

    if allow_access?(conn, profile.id) do
      render(conn, "index.html", profile: profile, subject: blog_post, entries: entries)
    else
      no_access!(conn, public_profile_blog_post_path(conn, :show, profile, blog_post))
    end
  end

  def index(conn, %{"profile_id" => profile_id, "photo_album_id" => photo_album_id, "photo_id" => photo_id} = params) do
    profile     = Repo.get!(User, profile_id)
    photo_album = assoc(profile, :photo_albums) |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> Repo.get!(photo_id)
    entries     = find_entries(photo, params)

    if allow_access?(conn, profile.id) do
      render(conn, "index.html", profile: profile, photo_album: photo_album, subject: photo, entries: entries)
    else
      no_access!(conn, public_profile_photo_album_photo_path(conn, :show, profile, photo_album, photo))
    end
  end

  def index(conn, %{"profile_id" => profile_id, "photo_album_id" => photo_album_id} = params) do
    profile     = Repo.get!(User, profile_id)
    photo_album = assoc(profile, :photo_albums) |> Repo.get!(photo_album_id)
    entries     = find_entries(photo_album, params)

    if allow_access?(conn, profile.id) do
      render(conn, "index.html", profile: profile, subject: photo_album, entries: entries)
    else
      no_access!(conn, public_profile_photo_album_path(conn, :show, profile, photo_album))
    end
  end

  def index(conn, %{"profile_id" => profile_id} = params) do
    profile = Repo.get!(User, profile_id)
    entries = find_entries(profile, params)

    if allow_access?(conn, profile.id) do
      render(conn, "index.html", subject: profile, entries: entries)
    else
      no_access!(conn, public_profile_path(conn, :show, profile))
    end
  end

  def find_entries(subject, params) do
    assoc(subject, :visitor_log_entries)
    |> VisitorLogEntry.newest
    |> preload(:user)
    |> Repo.paginate(page: sanitized_page(params["page"]))
  end

  defp allow_access?(conn, owner_id) do
    visitor = current_resource(conn)
    User.admin?(visitor) || owner_id == visitor.id
  end

  defp no_access!(conn, redirect_path) do
    conn
    |> put_flash(:error, gettext("You do not have access to that page!"))
    |> redirect(to: redirect_path)
    |> halt
  end
end
