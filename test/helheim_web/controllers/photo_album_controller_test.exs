defmodule HelheimWeb.PhotoAlbumControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.PhotoAlbum

  @valid_upload %Plug.Upload{path: "test/files/1.0MB.jpg", filename: "1.0MB.jpg"}
  @valid_attrs %{description: "Description Text", title: "Title String", visibility: "public"}
  @invalid_attrs %{description: "   ", title: "   "}

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an existing user id", %{conn: conn, user: user} do
      conn = get conn, "/profiles/#{user.id}/photo_albums"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an non-existing user id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/999999/photo_albums"
      end
    end

    test "it only shows photo albums from the specified user", %{conn: conn} do
      photo_album_1 = insert(:photo_album, title: "Album 1")
      photo_album_2 = insert(:photo_album, title: "Album 2")
      conn = get conn, "/profiles/#{photo_album_1.user.id}/photo_albums"
      assert conn.resp_body =~ photo_album_1.title
      refute conn.resp_body =~ photo_album_2.title
    end

    test "it shows a create new button when you're browsing your own photo albums", %{conn: conn, user: user} do
      conn = get conn, "/profiles/#{user.id}/photo_albums"
      assert conn.resp_body =~ gettext("Create New")
    end

    test "it does not show a create new button when you're browsing another users photo albums", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/photo_albums"
      refute conn.resp_body =~ gettext("Create New")
    end

    test "it shows both public, verified_only, friends_only and private albums when browsing your own photo albums", %{conn: conn, user: user} do
      refute user.verified_at
      photo_album_1 = insert(:photo_album, user: user, title: "Album 1", visibility: "public")
      photo_album_2 = insert(:photo_album, user: user, title: "Album 2", visibility: "friends_only")
      photo_album_3 = insert(:photo_album, user: user, title: "Album 3", visibility: "private")
      photo_album_4 = insert(:photo_album, user: user, title: "Album 4", visibility: "verified_only")
      conn = get conn, "/profiles/#{user.id}/photo_albums"
      assert conn.resp_body =~ photo_album_1.title
      assert conn.resp_body =~ photo_album_2.title
      assert conn.resp_body =~ photo_album_3.title
      assert conn.resp_body =~ photo_album_4.title
    end

    test "it shows only public albums when browsing another users photo albums", %{conn: conn} do
      user = insert(:user, verified_at: nil)
      photo_album_1 = insert(:photo_album, user: user, title: "Album 1", visibility: "public")
      photo_album_2 = insert(:photo_album, user: user, title: "Album 2", visibility: "friends_only")
      photo_album_3 = insert(:photo_album, user: user, title: "Album 3", visibility: "private")
      photo_album_4 = insert(:photo_album, user: user, title: "Album 3", visibility: "verified_only")
      conn = get conn, "/profiles/#{user.id}/photo_albums"
      assert conn.resp_body =~ photo_album_1.title
      refute conn.resp_body =~ photo_album_2.title
      refute conn.resp_body =~ photo_album_3.title
      refute conn.resp_body =~ photo_album_4.title
    end

    test "it redirects to a block page when the specified profile is blocking the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      conn  = get conn, "/profiles/#{block.blocker.id}/photo_albums"
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end

    test "does not show photo albums that are set to private and the current user is not the author of the photo album", %{conn: conn} do
      photo_album = insert(:photo_album, visibility: "private", title: "My private photo album")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums"
      refute conn.resp_body =~ photo_album.title
    end

    test "shows photo albums that are set to private and the current user is the author of the photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "private", title: "My private photo album")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums"
      assert conn.resp_body =~ photo_album.title
    end

    test "does not show photo albums that are set to friends_only and the current user is not friends with the author of the photo album", %{conn: conn} do
      photo_album = insert(:photo_album, visibility: "friends_only", title: "My friends_only photo album")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums"
      refute conn.resp_body =~ photo_album.title
    end

    test "shows photo albums that are set to verified_only and the current user is verified", %{conn: conn} do
      user = insert(:user, verified_at: Timex.now)
      photo_album = insert(:photo_album, user: user, visibility: "private", title: "My verified_only photo album")
      conn = conn
             |> sign_in(user)
             |> get("/profiles/#{photo_album.user.id}/photo_albums")
      assert conn.resp_body =~ photo_album.title
    end

    test "shows photo albums that are set to friends_only and the current user is friends with the author of the photo album", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship, sender: user, recipient: author)
      photo_album = insert(:photo_album, user: author, visibility: "friends_only", title: "My friends_only photo album")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums"
      assert conn.resp_body =~ photo_album.title
    end

    test "shows photo albums that are set to friends_only and the current user is the author of the photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "friends_only", title: "My friends_only photo album")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums"
      assert conn.resp_body =~ photo_album.title
    end

    test "does not show photo albums that are set to friends_only and the current user is only pending friends with the author of the photo album", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship_request, sender: user, recipient: author)
      photo_album = insert(:photo_album, user: author, visibility: "friends_only", title: "My friends_only photo album")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums"
      refute conn.resp_body =~ photo_album.title
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/photo_albums"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/photo_albums/new"
      assert html_response(conn, 200) =~ gettext("New Photo Album")
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/photo_albums/new"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new photo album and associates it with the signed in user when posting valid params", %{conn: conn, user: user} do
      conn = post conn, "/photo_albums", photo_album: @valid_attrs
      photo_album = Repo.one(PhotoAlbum)
      assert photo_album.title == @valid_attrs.title
      assert photo_album.description == @valid_attrs.description
      assert photo_album.user_id == user.id
      assert redirected_to(conn) == public_profile_photo_album_path(conn, :show, user, photo_album)
    end

    test "it does not create a new photo album and re-renders the new template when posting invalid params", %{conn: conn} do
      conn = post conn, "/photo_albums", photo_album: @invalid_attrs
      refute Repo.one(PhotoAlbum)
      assert html_response(conn, 200) =~ gettext("New Photo Album")
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a new photo album and instead redirects to the login page", %{conn: conn} do
      conn = post conn, "/photo_albums", photo_album: @valid_attrs
      refute Repo.one(PhotoAlbum)
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an existing photo album id matching an existing user id", %{conn: conn} do
      photo_album = insert(:photo_album)
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying a non-existant photo album id", %{conn: conn, user: user} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/1"
      end
    end

    test "it redirects to an error page when supplying a user id that does not own the photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}"
      end
    end

    test "it only shows photos from the photo album", %{conn: conn} do
      photo_album_1 = insert(:photo_album)
      photo_album_2 = insert(:photo_album, user: photo_album_1.user)
      photo_1 = create_photo(photo_album_1, %{title: "Photo A"})
      photo_2 = create_photo(photo_album_2, %{title: "Photo B"})
      conn = get conn, "/profiles/#{photo_album_1.user.id}/photo_albums/#{photo_album_1.id}"
      assert conn.resp_body =~ photo_1.title
      refute conn.resp_body =~ photo_2.title
    end

    test "it allows viewing a public photo album whether you own it or not", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "public")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)

      photo_album = insert(:photo_album, visibility: "public")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)
    end

    test "it only allows viewing a verified_only photo_album if you are verified or own it", %{conn: conn, user: user} do
      refute user.verified_at
      photo_album = insert(:photo_album, user: user, visibility: "verified_only")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)

      photo_album = insert(:photo_album, visibility: "verified_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      end

      user = insert(:user, verified_at: Timex.now)
      photo_album = insert(:photo_album, user: user, visibility: "verified_only")
      conn = build_conn() |> sign_in(user) |> get("/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}")
      assert html_response(conn, 200)
    end

    test "it only allows viewing a friends_only photo_album if you own it", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "friends_only")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)

      photo_album = insert(:photo_album, visibility: "friends_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      end
    end

    test "it only allows viewing a private photo_album if you own it", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "private")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)

      photo_album = insert(:photo_album, visibility: "private")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      end
    end

    test "it only shows the upload form when viewing your own photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert conn.resp_body =~ gettext("Upload Photos")

      photo_album = insert(:photo_album)
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      refute conn.resp_body =~ gettext("Upload Photos")
    end

    test_with_mock "it tracks the view", %{conn: conn, user: user},
      Helheim.VisitorLogEntry, [:passthrough], [track!: fn(_user, _subject) -> {:ok} end] do

      photo_album = insert(:photo_album)
      get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert_called Helheim.VisitorLogEntry.track!(user, Repo.get(PhotoAlbum, photo_album.id))
    end

    test "it redirects to a block page when the specified profile is blocking the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      photo_album = insert(:photo_album, user: block.blocker)
      conn  = get conn, "/profiles/#{block.blocker.id}/photo_albums/#{photo_album.id}"
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end

    test "redirects to an error page when the photo album is set to private and the current user is not the author of the photo album", %{conn: conn} do
      photo_album = insert(:photo_album, visibility: "private")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      end
    end

    test "successfully shows a photo album that is set to private when the current user is the author of the photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "private")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)
    end

    test "redirects to an error page when the photo album is set to friends_only and the current user is not friends with the author of the photo album", %{conn: conn} do
      photo_album = insert(:photo_album, visibility: "friends_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      end
    end

    test "successfully shows a photo album that is set to friends_only when the current user is the author of the photo album", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, visibility: "friends_only")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)
    end

    test "successfully shows a photo album that is set to private when the current user is friends with the author of the photo album", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship, sender: user, recipient: author)
      photo_album = insert(:photo_album, user: author, visibility: "friends_only")
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert html_response(conn, 200)
    end

    test "redirects to an error page when the photo album is set to friends_only and the current user is only pending friends with the author of the photo album", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship_request, sender: user, recipient: author)
      photo_album = insert(:photo_album, user: author, visibility: "friends_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      photo_album = insert(:photo_album)
      conn = get conn, "/profiles/#{photo_album.user.id}/photo_albums/#{photo_album.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an existing photo album id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      conn = get conn, "/photo_albums/#{photo_album.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Photo Album")
    end

    test "it redirects to an error page when supplying a non-existant photo album id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/photo_albums/1/edit"
      end
    end

    test "it redirects to an error page when supplying a photo album id belonging to another user", %{conn: conn} do
      photo_album = insert(:photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/photo_albums/#{photo_album.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      photo_album = insert(:photo_album)
      conn = get conn, "/photo_albums/#{photo_album.id}/edit"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it updates the photo album when posting valid params and existing photo album id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, title: "Foo", description: "Bar", visibility: "private")
      conn = put conn, "/photo_albums/#{photo_album.id}", photo_album: @valid_attrs
      photo_album = Repo.get(PhotoAlbum, photo_album.id)
      assert photo_album.title == @valid_attrs.title
      assert photo_album.description == @valid_attrs.description
      assert photo_album.visibility == @valid_attrs.visibility
      assert photo_album.user_id == user.id
      assert redirected_to(conn) == public_profile_photo_album_path(conn, :show, user, photo_album)
    end

    test "it does not update the photo album and re-renders the edit template when posting invalid params", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user, title: "Foo", description: "Bar", visibility: "private")
      conn = put conn, "/photo_albums/#{photo_album.id}", photo_album: @invalid_attrs
      photo_album = Repo.get(PhotoAlbum, photo_album.id)
      assert photo_album.title == "Foo"
      assert photo_album.description == "Bar"
      assert photo_album.visibility == "private"
      assert html_response(conn, 200) =~ gettext("Edit Photo Album")
    end

    test "it redirects to an error page when supplying a non-existant photo album id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/1", photo_album: @valid_attrs
      end
    end

    test "it does not update the photo album and redirects to an error page when supplying a photo album id belonging to another user", %{conn: conn} do
      photo_album = insert(:photo_album, title: "Foo", description: "Bar", visibility: "private")
      assert_error_sent :not_found, fn ->
        put conn, "/photo_albums/#{photo_album.id}", photo_album: @valid_attrs
      end
      photo_album = Repo.get(PhotoAlbum, photo_album.id)
      assert photo_album.title == "Foo"
      assert photo_album.description == "Bar"
      assert photo_album.visibility == "private"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the photo album and instead redirects to the sign in page", %{conn: conn} do
      photo_album = insert(:photo_album, title: "Foo", description: "Bar", visibility: "private")
      conn = put conn, "/photo_albums/#{photo_album.id}", photo_album: @valid_attrs
      assert redirected_to(conn) =~ session_path(conn, :new)
      photo_album = Repo.get(PhotoAlbum, photo_album.id)
      assert photo_album.title == "Foo"
      assert photo_album.description == "Bar"
      assert photo_album.visibility == "private"
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it deletes the photo album when posting existing photo album id belonging to the user", %{conn: conn, user: user},
      PhotoAlbum, [:passthrough], [delete!: fn(_photo_album) -> {:ok} end] do

      photo_album = Repo.get_by(PhotoAlbum, id: insert(:photo_album, user: user).id)
      conn = delete conn, "/photo_albums/#{photo_album.id}"
      assert_called PhotoAlbum.delete!(photo_album)
      assert redirected_to(conn) == public_profile_photo_album_path(conn, :index, user)
    end

    test "it redirects to an error page when supplying a non-existant photo album id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        delete conn, "/photo_albums/1"
      end
    end

    test_with_mock "it does not delete the photo album and redirects to an error page when supplying a photo album id belonging to another user", %{conn: conn},
      PhotoAlbum, [:passthrough], [delete!: fn(_photo_album) -> {:ok} end] do

      photo_album = Repo.get_by(PhotoAlbum, id: insert(:photo_album).id)
      assert_error_sent :not_found, fn ->
        delete conn, "/photo_albums/#{photo_album.id}"
      end
      refute called PhotoAlbum.delete!(photo_album)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not delete the photo album and instead redirects to the sign in page", %{conn: conn},
      PhotoAlbum, [:passthrough], [delete!: fn(_photo_album) -> {:ok} end] do

      photo_album = Repo.get_by(PhotoAlbum, id: insert(:photo_album).id)
      conn = delete conn, "/photo_albums/#{photo_album.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute called PhotoAlbum.delete!(photo_album)
    end
  end

  def create_photo(photo_album, attrs \\ %{}) do
    {:ok, photo} = photo_album
                   |> Ecto.build_assoc(:photos)
                   |> Helheim.Photo.changeset(Map.merge(attrs, %{file: @valid_upload}))
                   |> Repo.insert
    photo
  end
end
