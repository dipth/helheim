defmodule Helheim.PhotoAlbumTest do
  use Helheim.ModelCase
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

  describe "viewable_by/3" do
    test "when owner and viewer are different it returns only public albums" do
      owner        = insert(:user)
      viewer       = insert(:user)
      public_album = insert(:photo_album, user: owner, visibility: "public")
      insert(:photo_album, user: owner, visibility: "friends_only")
      insert(:photo_album, user: owner, visibility: "private")
      [album] = PhotoAlbum |> PhotoAlbum.viewable_by(owner, viewer) |> Repo.all
      assert album.id == public_album.id
    end

    test "when owner and viewer are the same it returns all albums" do
      owner = insert(:user)
      expected_albums = [
        insert(:photo_album, user: owner, visibility: "public"),
        insert(:photo_album, user: owner, visibility: "friends_only"),
        insert(:photo_album, user: owner, visibility: "private")
      ]
      expected_album_ids = expected_albums |> Enum.map(fn(a) -> a.id end) |> Enum.sort

      albums = PhotoAlbum |> PhotoAlbum.viewable_by(owner, owner) |> Repo.all
      album_ids = albums |> Enum.map(fn(a) -> a.id end) |> Enum.sort

      assert expected_album_ids == album_ids
    end
  end

  describe "delete/1" do
    test_with_mock "it calls Photo.delete! for each photo in the album",
      Photo, [:passthrough], [delete!: fn(_photo) -> {:ok} end] do

      photo_album = insert(:photo_album)
      photo1      = Repo.get_by(Photo, id: insert(:photo, photo_album: photo_album).id)
      photo2      = Repo.get_by(Photo, id: insert(:photo, photo_album: photo_album).id)
      photo3      = Repo.get_by(Photo, id: insert(:photo).id)

      PhotoAlbum.delete! photo_album

      assert called Photo.delete!(photo1)
      assert called Photo.delete!(photo2)
      refute called Photo.delete!(photo3)
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
