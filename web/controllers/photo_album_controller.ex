defmodule Helheim.PhotoAlbumController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.PhotoAlbum
  alias Helheim.Photo

  def index(conn, params = %{"profile_id" => user_id}) do
    user = Repo.get!(User, user_id)
    photo_albums =
      assoc(user, :photo_albums)
      |> PhotoAlbum.viewable_by(user, current_resource(conn))
      |> preload(:photos)
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", user: user, photo_albums: photo_albums)
  end

  def new(conn, _params) do
    user = current_resource(conn)
    changeset =
      user
        |> Ecto.build_assoc(:photo_albums)
        |> PhotoAlbum.changeset(%{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"photo_album" => photo_album_params}) do
    user = current_resource(conn)
    changeset =
      user
        |> Ecto.build_assoc(:photo_albums)
        |> PhotoAlbum.changeset(photo_album_params)

    case Repo.insert(changeset) do
      {:ok, photo_album} ->
        conn
        |> put_flash(:success, gettext("Photo album created successfully."))
        |> redirect(to: public_profile_photo_album_path(conn, :show, user, photo_album))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"profile_id" => user_id, "id" => id}) do
    user = Repo.get!(User, user_id)
    photo_album =
      assoc(user, :photo_albums)
      |> PhotoAlbum.viewable_by(user, current_resource(conn))
      |> Repo.get!(id)
    photos =
      assoc(photo_album, :photos)
      |> Photo.in_positional_order
      |> preload(:photo_album)
      |> Repo.all
    Helheim.VisitorLogEntry.track! current_resource(conn), photo_album
    render(conn, "show.html", user: user, photo_album: photo_album, photos: photos)
  end

  def edit(conn, %{"id" => id}) do
    user = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(id)
    changeset = PhotoAlbum.changeset(photo_album)
    render(conn, "edit.html", photo_album: photo_album, changeset: changeset)
  end

  def update(conn, %{"id" => id, "photo_album" => photo_album_params}) do
    user = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(id)
    changeset = PhotoAlbum.changeset(photo_album, photo_album_params)

    case Repo.update(changeset) do
      {:ok, photo_album} ->
        conn
        |> put_flash(:success, gettext("Photo album updated successfully."))
        |> redirect(to: public_profile_photo_album_path(conn, :show, user, photo_album))
      {:error, changeset} ->
        render(conn, "edit.html", photo_album: photo_album, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(id)

    PhotoAlbum.delete!(photo_album)

    conn
    |> put_flash(:success, gettext("Photo Album deleted successfully."))
    |> redirect(to: public_profile_photo_album_path(conn, :index, user))
  end
end
