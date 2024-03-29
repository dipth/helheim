defmodule HelheimWeb.PhotoController do
  use HelheimWeb, :controller
  alias Helheim.User
  alias Helheim.PhotoAlbum
  alias Helheim.Photo
  alias Helheim.Comment
  alias Helheim.PhotoService
  import HelheimWeb.ErrorHelpers, only: [translate_error: 1]

  plug :find_user when action in [:show]
  plug HelheimWeb.Plug.EnforceBlock when action in [:show]

  def index(conn, params) do
    photos = Photo
             |> Photo.visible_by(current_resource(conn))
             |> Photo.newest
             |> Photo.not_private
             |> Photo.not_from_ignoree(conn.assigns[:ignoree_ids])
             |> preload(photo_album: :user)
             |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", photos: photos)
  end

  def create(conn, %{"photo_album_id" => photo_album_id, "file" => file, "photo" => photo}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)

    case PhotoService.create!(user, photo_album, file, photo["nsfw"]) do
      {:ok, photo} ->
        photo = Photo |> preload(:photo_album) |> Repo.get(photo.id)
        render(conn, "create.js", user: user, photo_album: photo_album, photo: photo)
      {:error, changeset} ->
        send_resp(conn, 403, translate_error(changeset.errors[:file]))
    end
  end

  def show(conn, %{"profile_id" => _, "photo_album_id" => photo_album_id, "id" => id} = params) do
    user        = conn.assigns[:user]
    photo_album = assoc(user, :photo_albums)
                  |> PhotoAlbum.visible_by(current_resource(conn))
                  |> Repo.get!(photo_album_id)
    photo      = assoc(photo_album, :photos) |> preload(:photo_album) |> Repo.get!(id)
    prev_photo = Photo.previous(photo)
    next_photo = Photo.next(photo)
    comments   = assoc(photo, :comments)
                 |> Comment.not_deleted
                 |> Comment.newest
                 |> Comment.with_preloads
                 |> Repo.paginate(page: sanitized_page(params["page"]))
    Helheim.VisitorLogEntry.track! current_resource(conn), photo
    render(conn, "show.html", user: user, photo_album: photo_album, photo: photo, prev_photo: prev_photo, next_photo: next_photo, comments: comments)
  end

  def edit(conn, %{"photo_album_id" => photo_album_id, "id" => id}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> Repo.get!(id)
    photo_albums = assoc(user, :photo_albums) |> PhotoAlbum.alphabetical() |> Repo.all()
    changeset   = Photo.changeset(photo)

    render(conn, "edit.html", user: user, photo_album: photo_album, photo: photo, photo_albums: photo_albums, changeset: changeset)
  end

  def update(conn, %{"photo_album_id" => photo_album_id, "id" => id, "photo" => photo_params}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> Repo.get!(id)
    photo_albums = assoc(user, :photo_albums) |> PhotoAlbum.alphabetical() |> Repo.all()
    changeset   = Photo.update_changeset(photo, photo_albums, photo_params)

    case Repo.update(changeset) do
      {:ok, photo} ->
        conn
        |> put_flash(:success, gettext("Photo details updated successfully."))
        |> redirect(to: public_profile_photo_album_photo_path(conn, :show, user, photo.photo_album_id, photo))
      {:error, changeset} ->
        render(conn, "edit.html", user: user, photo_album: photo_album, photo: photo, photo_albums: photo_albums, changeset: changeset)
    end
  end

  def delete(conn, %{"photo_album_id" => photo_album_id, "id" => id}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> Repo.get!(id)

    Photo.delete!(photo)

    conn
    |> put_flash(:success, gettext("Photo deleted successfully."))
    |> redirect(to: public_profile_photo_album_path(conn, :show, user, photo_album))
  end

  defp find_user(conn, _) do
    assign_user(conn, conn.params)
  end

  defp assign_user(conn, %{"profile_id" => profile_id}) do
    conn
    |> assign(:user, Repo.get!(User, profile_id))
  end
  defp assign_user(conn, _), do: conn
end
