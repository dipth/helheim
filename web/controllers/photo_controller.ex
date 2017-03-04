defmodule Helheim.PhotoController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.PhotoAlbum
  alias Helheim.Photo
  import Helheim.ErrorHelpers, only: [translate_error: 1]

  def create(conn, %{"photo_album_id" => photo_album_id, "file" => file}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)
    file_stats  = File.stat! file.path
    changeset   = photo_album
                  |> Ecto.build_assoc(:photos)
                  |> Photo.changeset(%{file: file, title: file.filename})
                  |> Ecto.Changeset.put_change(:file_size, file_stats.size)

    case Repo.insert(changeset) do
      {:ok, photo} ->
        render(conn, "create.js", user: user, photo_album: photo_album, photo: photo)
      {:error, changeset} ->
        send_resp(conn, 403, translate_error(changeset.errors[:file]))
    end
  end

  def show(conn, %{"profile_id" => user_id, "photo_album_id" => photo_album_id, "id" => id}) do
    user        = Repo.get!(User, user_id)
    photo_album = assoc(user, :photo_albums)
                  |> PhotoAlbum.viewable_by(user, current_resource(conn))
                  |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> preload(:photo_album) |> Repo.get!(id)
    Helheim.VisitorLogEntry.track! current_resource(conn), photo
    render(conn, "show.html", user: user, photo_album: photo_album, photo: photo)
  end

  def edit(conn, %{"photo_album_id" => photo_album_id, "id" => id}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> Repo.get!(id)
    changeset   = Photo.changeset(photo)

    render(conn, "edit.html", user: user, photo_album: photo_album, photo: photo, changeset: changeset)
  end

  def update(conn, %{"photo_album_id" => photo_album_id, "id" => id, "photo" => photo_params}) do
    user        = current_resource(conn)
    photo_album = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)
    photo       = assoc(photo_album, :photos) |> Repo.get!(id)
    changeset   = Photo.changeset(photo, photo_params)

    case Repo.update(changeset) do
      {:ok, photo} ->
        conn
        |> put_flash(:success, gettext("Photo details updated successfully."))
        |> redirect(to: public_profile_photo_album_photo_path(conn, :show, user, photo_album, photo))
      {:error, changeset} ->
        render(conn, "edit.html", user: user, photo_album: photo_album, photo: photo, changeset: changeset)
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
end
