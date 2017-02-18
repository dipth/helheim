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

  describe "with_latest_photo/1" do
    test "it preloads the latest photo of the album" do
      photo_album = insert(:photo_album)
      insert(:photo, photo_album: photo_album)
      latest_photo = insert(:photo, photo_album: photo_album)
      photo_album = PhotoAlbum |> PhotoAlbum.with_latest_photo() |> Repo.one
      [photo] = photo_album.photos
      assert photo.id == latest_photo.id
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
end
