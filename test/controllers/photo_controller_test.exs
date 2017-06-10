defmodule Helheim.PhotoControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.Photo

  @valid_file %Plug.Upload{path: "test/files/1.0MB.jpg", filename: "1.0MB.jpg"}
  @invalid_file %{}

  @valid_attrs %{title: "Pretty Photo", description: "Isn't it pretty?"}
  @invalid_attrs %{title: "", description: ""}

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/photos"
      assert html_response(conn, 200)
    end

    test "it shows photos from all users", %{conn: conn} do
      photo_1 = insert(:photo, title: "Photo 1")
      photo_2 = insert(:photo, title: "Photo 2")
      conn = get conn, "/photos"
      assert conn.resp_body =~ photo_1.title
      assert conn.resp_body =~ photo_2.title
    end

    test "it does not show private or friends only photos", %{conn: conn} do
      photo_album_1 = insert(:photo_album, visibility: "private")
      photo_album_2 = insert(:photo_album, visibility: "friends_only")
      photo_1 = insert(:photo, title: "Photo 1", photo_album: photo_album_1)
      photo_2 = insert(:photo, title: "Photo 2", photo_album: photo_album_2)
      conn = get conn, "/photos"
      refute conn.resp_body =~ photo_1.title
      refute conn.resp_body =~ photo_2.title
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/photos"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new photo when posting a valid file and a photo_id belonging to the user", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      post conn, "/photo_albums/#{photo_album.id}/photos", file: @valid_file, photo: %{nsfw: false}
      photo = Repo.one(Photo)
      assert photo.title          == "1.0MB.jpg"
      assert photo.file_size      == 999631
      assert photo.photo_album_id == photo_album.id
      assert photo.file
    end

    test "it does not create a new photo when posting a non existing photo_id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        post conn, "/photo_albums/1/photos", file: @valid_file, photo: %{nsfw: false}
      end
      refute Repo.one(Photo)
    end

    test "it does not create a new photo when posting a photo_id belonging to another user", %{conn: conn} do
      photo_album = insert(:photo_album)
      assert_error_sent :not_found, fn ->
        post conn, "/photo_albums/#{photo_album.id}/photos", file: @valid_file, photo: %{nsfw: false}
      end
      refute Repo.one(Photo)
    end

    test "it does not create a new photo when posting an invalid file", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      assert_error_sent 500, fn ->
        post conn, "/photo_albums/#{photo_album.id}/photos", file: @invalid_file, photo: %{nsfw: false}
      end
      refute Repo.one(Photo)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a new photo and instead redirects to the login page", %{conn: conn} do
      photo_album = insert(:photo_album)
      post conn, "/photo_albums/#{photo_album.id}/photos", file: @valid_file, photo: %{nsfw: false}
      refute Repo.one(Photo)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an correct combination of id, photo_album_id and user_id", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying a non-existant id, photo_album_id or user_id", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)

      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id + 1}"
      end

      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id + 1}/photos/#{photo.id}"
      end

      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id + 1}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      end
    end

    test "it redirects to an error page when supplying the id of a photo that is not in the specified photo album", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(insert(:photo_album, user: user))

      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      end
    end

    test "it redirects to an error page when supplying the id of a photo album that is not owned by the specified user", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album)

      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      end
    end

    test "it allows viewing a public photo whether you own it or not", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "public")
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert html_response(conn, 200)

      user        = insert(:user)
      photo_album = insert(:photo_album, user: user, visibility: "public")
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert html_response(conn, 200)
    end

    test "it only allows viewing a friends_only photo if you own it", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "friends_only")
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert html_response(conn, 200)

      user        = insert(:user)
      photo_album = insert(:photo_album, user: user, visibility: "friends_only")
      photo       = create_photo(photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      end
    end

    test "it only allows viewing a private photo if you own it", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "private")
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert html_response(conn, 200)

      user        = insert(:user)
      photo_album = insert(:photo_album, user: user, visibility: "private")
      photo       = create_photo(photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      end
    end

    test "it only shows the edit and delete buttons if you own the photo", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert conn.resp_body =~ gettext("Edit Photo Details")
      assert conn.resp_body =~ gettext("Delete")

      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      refute conn.resp_body =~ gettext("Edit Photo Details")
      refute conn.resp_body =~ gettext("Delete")
    end

    test_with_mock "it tracks the view", %{conn: conn, user: user},
      Helheim.VisitorLogEntry, [:passthrough], [track!: fn(_user, _subject) -> {:ok} end] do

      profile     = insert(:user)
      photo_album = insert(:photo_album, user: profile)
      photo       = create_photo(photo_album)
      get conn, "/profiles/#{profile.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      photo = Photo |> preload(:photo_album) |> Repo.get(photo.id)
      assert called Helheim.VisitorLogEntry.track!(user, photo)
    end

    test "it redirects to a block page when the specified profile is blocking the current user", %{conn: conn, user: user} do
      block       = insert(:block, blockee: user)
      photo_album = insert(:photo_album, user: block.blocker)
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{block.blocker.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end

    test "does not show deleted comments", %{conn: conn} do
      comment     = insert(:photo_comment, deleted_at: DateTime.utc_now, body: "This is a deleted comment")
      photo       = comment.photo
      photo_album = photo.photo_album
      profile     = photo_album.user
      conn        = get conn, "/profiles/#{profile.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      refute html_response(conn, 200) =~ "This is a deleted comment"
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album)
      conn        = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying a correct combination of photo_album_id and id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)
      conn        = get conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Photo Details")
    end

    test "it redirects to an error page when supplying a non-existant id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      assert_error_sent :not_found, fn ->
        get conn, "/photo_albums/#{photo_album.id}/photos/1/edit"
      end
    end

    test "it redirects to an error page when supplying an id of a photo from another photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(insert(:photo_album, user: user))
      assert_error_sent :not_found, fn ->
        get conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}/edit"
      end
    end

    test "it redirects to an error page when supplying a photo album id belonging to another user", %{conn: conn} do
      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album)
      conn        = get conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it updates the photo details when posting valid params and existing photo_album_id and id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album, %{title: "Foo", description: "Bar"})
      conn        = put conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}", photo: @valid_attrs
      photo       = Repo.get(Photo, photo.id)
      assert photo.title         == @valid_attrs.title
      assert photo.description   == @valid_attrs.description
      assert redirected_to(conn) == public_profile_photo_album_photo_path(conn, :show, user, photo_album, photo)
    end

    test "it does not update the photo and re-renders the edit template when posting invalid params", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album, %{title: "Foo", description: "Bar"})
      conn        = put conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}", photo: @invalid_attrs
      photo       = Repo.get(Photo, photo.id)
      assert photo.title              == "Foo"
      assert photo.description        == "Bar"
      assert html_response(conn, 200) =~ gettext("Edit Photo Details")
    end

    test "it redirects to an error page when supplying a non-existant photo_album_id or id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)

      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id + 1}", photo: @valid_attrs
      end

      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo_album.id + 1}/photos/#{photo.id}", photo: @valid_attrs
      end
    end

    test "it redirects to an error page when supplying an id of a photo belonging to another photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(insert(:photo_album, user: user))

      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}", photo: @valid_attrs
      end
    end

    test "it does not update the photo and redirects to an error page when supplying a photo_album_id belonging to another user", %{conn: conn} do
      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album, %{title: "Foo", description: "Bar"})

      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}", photo: @valid_attrs
      end

      photo = Repo.get(Photo, photo.id)
      assert photo.title       == "Foo"
      assert photo.description == "Bar"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the photo and instead redirects to the sign in page", %{conn: conn} do
      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album, %{title: "Foo", description: "Bar"})
      conn        = put conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}", photo: @valid_attrs
      photo       = Repo.get(Photo, photo.id)
      assert redirected_to(conn) == session_path(conn, :new)
      assert photo.title         == "Foo"
      assert photo.description   == "Bar"
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it deletes the photo when posting existing photo_album_id and id belonging to the user", %{conn: conn, user: user},
      Photo, [:passthrough], [delete!: fn(_photo) -> {:ok} end] do

      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)
      conn        = delete conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      assert called Photo.delete!(Repo.get(Photo, photo.id))
      assert redirected_to(conn) == public_profile_photo_album_path(conn, :show, user, photo_album)
    end

    test_with_mock "it redirects to an error page when supplying a non-existant photo_album_id or photo_id", %{conn: conn, user: user},
      Photo, [:passthrough], [delete!: fn(_photo) -> {:ok} end] do

      photo_album = insert(:photo_album, user: user)
      photo       = create_photo(photo_album)

      assert_error_sent :not_found, fn ->
        delete conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id + 1}"
      end

      assert_error_sent :not_found, fn ->
        delete conn, "/photo_albums/#{photo_album.id + 1}/photos/#{photo.id}"
      end

      refute called Photo.delete!(photo)
    end

    test_with_mock "it does not delete the photo album and redirects to an error page when supplying an id of a photo belonging to another user", %{conn: conn},
      Photo, [:passthrough], [delete!: fn(_photo) -> {:ok} end] do

      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album)

      assert_error_sent :not_found, fn ->
        delete conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}"
      end

      refute called Photo.delete!(photo)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not delete the photo and instead redirects to the sign in page", %{conn: conn},
      Photo, [:passthrough], [delete!: fn(_photo) -> {:ok} end] do

      photo_album = insert(:photo_album)
      photo       = create_photo(photo_album)
      conn        = delete conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}"

      assert redirected_to(conn) == session_path(conn, :new)
      refute called Photo.delete!(photo)
    end
  end

  def create_photo(photo_album, attrs \\ %{title: "Photo"}) do
    {:ok, photo} = photo_album
                   |> Ecto.build_assoc(:photos)
                   |> Helheim.Photo.changeset(Map.merge(attrs, %{file: @valid_file}))
                   |> Repo.insert
    photo
  end
end
