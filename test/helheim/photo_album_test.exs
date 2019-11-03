defmodule Helheim.PhotoAlbumTest do
  use Helheim.DataCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.PhotoAlbum
  alias Helheim.Photo

  describe "changeset/2" do
    @valid_attrs %{title: "Foo", description: "Bar", visibility: "public"}

    test "it is valid with valid attrs" do
      changeset = PhotoAlbum.changeset(%PhotoAlbum{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a title" do
      changeset = PhotoAlbum.changeset(%PhotoAlbum{}, Map.delete(@valid_attrs, :title))
      refute changeset.valid?
    end

    test "it requires a visibility" do
      changeset = PhotoAlbum.changeset(%PhotoAlbum{}, Map.delete(@valid_attrs, :visibility))
      refute changeset.valid?
    end

    test "it only allows valid visibilities" do
      Enum.each(Helheim.Visibility.visibilities, fn(v) ->
        changeset = PhotoAlbum.changeset(%PhotoAlbum{}, Map.merge(@valid_attrs, %{visibility: v}))
        assert changeset.valid?
      end)

      changeset = PhotoAlbum.changeset(%PhotoAlbum{}, Map.merge(@valid_attrs, %{visibility: "invalid"}))
      refute changeset.valid?
    end

    test "it trims the title and description" do
      changeset = PhotoAlbum.changeset(%PhotoAlbum{}, Map.merge(@valid_attrs, %{title: "   Baz   ", description: "   Baz   "}))
      assert changeset.changes.title == "Baz"
      assert changeset.changes.description == "Baz"
    end

    test "it does not allow changing the user_id" do
      changeset = PhotoAlbum.changeset(%PhotoAlbum{}, Map.merge(@valid_attrs, %{user_id: 123}))
      refute changeset.changes[:user_id]
    end
  end

  describe "visible_by/2" do
    test "always returns photo albums that are set to public" do
      user         = insert(:user)
      photo_album  = insert(:photo_album, visibility: "public")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "always returns private photo albums if the user is the same as the user of the photo album" do
      user         = insert(:user)
      photo_album  = insert(:photo_album, user: user, visibility: "private")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "always returns verified_only photo albums if the user is the same as the user of the photo album" do
      user         = insert(:user, verified_at: nil)
      photo_album  = insert(:photo_album, user: user, visibility: "verified_only")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "always returns verified_only photo albums if the user is verified" do
      user         = insert(:user, verified_at: Timex.now)
      photo_album  = insert(:photo_album, visibility: "verified_only")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "always returns friends_only photo albums if the user is the same as the user of the photo album" do
      user         = insert(:user)
      photo_album  = insert(:photo_album, user: user, visibility: "friends_only")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "never returns private photo albums if the user is not the same as the user of the photo album" do
      user         = insert(:user)
      _photo_album = insert(:photo_album, visibility: "private")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      assert photo_albums == []
    end

    test "never returns verified_only photo albums if the user is not verified" do
      user = insert(:user, verified_at: nil)
      _photo_album = insert(:photo_album, visibility: "verified_only")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      assert photo_albums == []
    end

    test "never returns friends_only photo albums if the user is not friends with the user of the photo album" do
      user         = insert(:user)
      _photo_album = insert(:photo_album, visibility: "friends_only")
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      assert photo_albums == []
    end

    test "always returns friends_only photo albums if the user is befriended by the user of the photo album" do
      author       = insert(:user)
      user         = insert(:user)
      photo_album  = insert(:photo_album, user: author, visibility: "friends_only")
      _friendship  = insert(:friendship, sender: author, recipient: user)
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "always returns friends_only photo albums if the user of the photo album is befriended by the user" do
      author       = insert(:user)
      user         = insert(:user)
      photo_album  = insert(:photo_album, user: author, visibility: "friends_only")
      _friendship  = insert(:friendship, sender: user, recipient: author)
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      ids          = Enum.map photo_albums, fn(c) -> c.id end
      assert [photo_album.id] == ids
    end

    test "never returns friends_only photo albums if the user is pending friendship from the user of the photo album" do
      author       = insert(:user)
      user         = insert(:user)
      _photo_album = insert(:photo_album, user: author, visibility: "friends_only")
      _friendship  = insert(:friendship_request, sender: author, recipient: user)
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      assert photo_albums == []
    end

    test "never returns friends_only photo albums if the user of the photo album is pending friendship from the user" do
      author       = insert(:user)
      user         = insert(:user)
      _photo_album = insert(:photo_album, user: author, visibility: "friends_only")
      _friendship  = insert(:friendship_request, sender: user, recipient: author)
      photo_albums = PhotoAlbum |> PhotoAlbum.visible_by(user) |> Repo.all
      assert photo_albums == []
    end
  end

  describe "delete/1" do
    test_with_mock "it calls Photo.delete! for each photo in the album",
      Photo, [:passthrough], [delete!: fn(_photo) -> {:ok} end] do

      photo_album = insert(:photo_album)
      photo1      = insert(:photo, photo_album: photo_album)
      photo2      = insert(:photo, photo_album: photo_album)
      photo3      = insert(:photo)

      PhotoAlbum.delete! photo_album

      assert_called_with_pattern Photo, :delete!, fn(args) ->
        photo_id = photo1.id
        [%Photo{id: ^photo_id}] = args
      end
      assert_called_with_pattern Photo, :delete!, fn(args) ->
        photo_id = photo2.id
        [%Photo{id: ^photo_id}] = args
      end
      refute_called_with_pattern Photo, :delete!, fn(args) ->
        photo_id = photo3.id
        [%Photo{id: ^photo_id}] = args
      end
    end

    test "it deletes the photo album" do
      photo_album = insert(:photo_album)
      PhotoAlbum.delete! photo_album
      refute Repo.get(PhotoAlbum, photo_album.id)
    end
  end

  describe "reposition_photos!/2" do
    test "changes the positions of the photos in the specified photo_album and the specified ids to match the index in the array of ids" do
      photo_album = insert(:photo_album)
      photo_1 = insert(:photo, photo_album: photo_album, position: 0)
      photo_2 = insert(:photo, photo_album: photo_album, position: 0)
      photo_3 = insert(:photo, photo_album: photo_album, position: 0)

      PhotoAlbum.reposition_photos!(photo_album, [photo_2.id, photo_3.id, photo_1.id])

      photo_1 = Repo.get(Photo, photo_1.id)
      photo_2 = Repo.get(Photo, photo_2.id)
      photo_3 = Repo.get(Photo, photo_3.id)

      assert photo_1.position == 2
      assert photo_2.position == 0
      assert photo_3.position == 1
    end

    test "does not change the position values of photos from other albums" do
      photo_album = insert(:photo_album)
      photo_1 = insert(:photo, photo_album: photo_album, position: 9)
      photo_2 = insert(:photo, position: 9)
      PhotoAlbum.reposition_photos!(photo_album, [photo_1.id])
      photo_2 = Repo.get(Photo, photo_2.id)
      assert photo_2.position == 9
    end

    test "ignores ids of photos from other albums" do
      photo_album = insert(:photo_album)
      photo = insert(:photo, position: 9)
      PhotoAlbum.reposition_photos!(photo_album, [photo.id])
      photo = Repo.get(Photo, photo.id)
      assert photo.position == 9
    end
  end
end
