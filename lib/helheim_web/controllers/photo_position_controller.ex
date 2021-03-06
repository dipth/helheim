defmodule HelheimWeb.PhotoPositionController do
  use HelheimWeb, :controller
  alias Helheim.PhotoAlbum

  def update(conn, %{"photo_album_id" => photo_album_id, "photo_ids" => photo_ids}) do
    photo_ids     = parse_photo_ids(photo_ids)
    user          = current_resource(conn)
    photo_album   = assoc(user, :photo_albums) |> Repo.get!(photo_album_id)

    PhotoAlbum.reposition_photos!(photo_album, photo_ids)
    text(conn, "OK")
  end

  defp parse_photo_ids(photo_ids) do
    Enum.map(photo_ids, fn(str_id) ->
      {id, _} = Integer.parse(str_id)
      id
    end)
  end
end
