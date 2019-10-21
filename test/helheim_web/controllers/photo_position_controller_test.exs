defmodule HelheimWeb.PhotoPositionControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.PhotoAlbum

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it updates the positions of the specified photos in the specified album and returns a successful response", %{conn: conn, user: user},
      PhotoAlbum, [:passthrough], [reposition_photos!: fn(_photo_album, _photo_ids) -> {3, nil} end] do

      photo_album = Repo.get(PhotoAlbum, insert(:photo_album, user: user).id)
      conn = put conn, "/photo_albums/#{photo_album.id}/photo_positions", photo_ids: ["1", "2", "3"]

      assert_called PhotoAlbum.reposition_photos!(photo_album, [1,2,3])
      assert conn.state == :sent
      assert conn.status == 200
    end

    test "it redirects to an error page when supplying a non-existant photo album id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/1/photo_positions", photo_ids: ["1", "2", "3"]
      end
    end

    test_with_mock "it does not update the positions of photos and redirects to an error page when supplying a photo album id belonging to another user", %{conn: conn},
      PhotoAlbum, [:passthrough], [reposition_photos!: fn(_photo_album, _photo_ids) -> raise("reposition_photos! called!") end] do

      photo_album = insert(:photo_album)
      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo_album.id}/photo_positions", photo_ids: ["1", "2", "3"]
      end
    end
  end

  describe "update/2 when not signed in" do
    test_with_mock "it does not update the positions of photos and instead redirects to the sign in page", %{conn: conn},
      PhotoAlbum, [:passthrough], [reposition_photos!: fn(_photo_album, _photo_ids) -> raise("reposition_photos! called!") end] do

      photo_album = insert(:photo_album)
      conn = put conn, "/photo_albums/#{photo_album.id}/photo_positions", photo_ids: ["1", "2", "3"]
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
