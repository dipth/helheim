defmodule Helheim.PhotoTest do
  use Helheim.DataCase
  import Mock
  alias Helheim.Repo
  alias Helheim.Photo

  @valid_upload %Plug.Upload{path: "test/files/1.0MB.jpg", filename: "1.0MB.jpg"}
  @valid_attrs %{title: "Cool Photo", file: @valid_upload, nsfw: false}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = new_changeset @valid_attrs
      assert changeset.valid?
    end

    test "it requires a title" do
      changeset = new_changeset Map.delete(@valid_attrs, :title)
      refute changeset.valid?
    end

    test "it requires a file" do
      changeset = new_changeset Map.delete(@valid_attrs, :file)
      refute changeset.valid?
    end

    test "it trims the title and description" do
      changeset = new_changeset Map.merge(@valid_attrs, %{title: "   Baz   ", description: "   Baz   "})
      assert changeset.changes.title == "Baz"
      assert changeset.changes.description == "Baz"
    end

    test "it sets a UUID" do
      changeset = new_changeset @valid_attrs
      assert changeset.changes.uuid
    end

    test "it correctly sets the position in incrementing fashion" do
      photo_album = insert(:photo_album)
      {:ok, photo} = new_changeset(@valid_attrs, photo_album) |> Repo.insert
      assert photo.position == 0
      {:ok, photo} = new_changeset(@valid_attrs, photo_album) |> Repo.insert
      assert photo.position == 1
      {:ok, photo} = new_changeset(@valid_attrs, photo_album) |> Repo.insert
      assert photo.position == 2
    end

    test "it never overwrites an existing UUID" do
      photo = insert(:photo)
      changeset = Photo.changeset(photo, %{title: "New Title"})
      refute changeset.changes[:uuid]
    end

    test "it does not allow changing the photo_album_id" do
      changeset = new_changeset Map.merge(@valid_attrs, %{photo_album_id: 123})
      refute changeset.changes[:photo_album_id]
    end

    test "it does not allow changing the file_size" do
      changeset = new_changeset Map.merge(@valid_attrs, %{file_size: 123})
      refute changeset.changes[:file_size]
    end

    test "it only accepts image files" do
      text_file = %Plug.Upload{path: "test/files/text.txt", filename: "text.txt"}
      changeset = new_changeset Map.merge(@valid_attrs, %{file: text_file})
      refute changeset.valid?

      fake_image = %Plug.Upload{path: "test/files/not_an_image.jpg", filename: "not_an_image.jpg"}
      changeset = new_changeset Map.merge(@valid_attrs, %{file: fake_image})
      refute changeset.valid?
    end

    test_with_mock "does not allow uploading files bigger than the max files size",
      Helheim.Photo, [:passthrough], [max_file_size: fn() -> 0.9 * 1000 * 1000 end] do
      changeset = new_changeset @valid_attrs
      refute changeset.valid?
    end

    test "does not allow uploading files bigger than the total space left for the user" do
      user = insert(:user, max_total_file_size: round(0.9 * 1000 * 1000))
      album = insert(:photo_album, user: user)
      changeset = new_changeset @valid_attrs, album
      refute changeset.valid?
    end
  end

  describe "newest/1" do
    test "it orders newer photos before older ones" do
      photo1 = insert(:photo)
      photo2 = insert(:photo)
      [first, last] = Photo |> Photo.newest |> Repo.all
      assert first.id == photo2.id
      assert last.id == photo1.id
    end
  end

  describe "public/1" do
    test "it only returns photos that are in a public photo album" do
      public_album       = insert(:photo_album, visibility: "public")
      friends_only_album = insert(:photo_album, visibility: "friends_only")
      private_album      = insert(:photo_album, visibility: "private")
      public_photo       = insert(:photo, photo_album: public_album)
      friends_only_photo = insert(:photo, photo_album: friends_only_album)
      private_photo      = insert(:photo, photo_album: private_album)
      photo_ids = Photo |> Photo.public |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(photo_ids, public_photo.id)
      refute Enum.member?(photo_ids, friends_only_photo.id)
      refute Enum.member?(photo_ids, private_photo.id)
    end
  end

  describe "newest_for_frontpage/1" do
    test "always returns public photos" do
      viewer      = insert(:user)
      photo_album = insert(:photo_album, visibility: "public")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "returns verified_only photos if the viewer is the author of the photo" do
      viewer      = insert(:user, verified_at: nil)
      photo_album = insert(:photo_album, user: viewer, visibility: "verified_only")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "returns verified_only photos if the viewer is verified" do
      viewer      = insert(:user, verified_at: Timex.now)
      photo_album = insert(:photo_album, visibility: "verified_only")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "returns friends_only photos if the viewer is the author of the photo" do
      viewer      = insert(:user)
      photo_album = insert(:photo_album, user: viewer, visibility: "friends_only")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "returns friends_only photos if the viewer is friends with the author of the photo" do
      viewer      = insert(:user)
      photo_album = insert(:photo_album, visibility: "friends_only")
      photo       = insert(:photo, photo_album: photo_album)
      _friendship = insert(:friendship, sender: viewer, recipient: photo_album.user)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "does not return friends_only photos if the viewer is not the author of the photo or friends with the author of the photo" do
      viewer      = insert(:user)
      photo_album = insert(:photo_album, visibility: "friends_only")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      refute Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "does not return friends_only photos if the viewer is only pending friends with the author of the photo" do
      viewer      = insert(:user)
      photo_album = insert(:photo_album, visibility: "friends_only")
      photo       = insert(:photo, photo_album: photo_album)
      _friendship = insert(:friendship_request, sender: viewer, recipient: photo_album.user)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      refute Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "does not return verified_only photos if the viewer is not the author of the photo or verified" do
      viewer      = insert(:user, verified_at: nil)
      photo_album = insert(:photo_album, visibility: "verified_only")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      refute Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "never returns private photos" do
      viewer      = insert(:user)
      photo_album = insert(:photo_album, user: viewer, visibility: "private")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo.newest_for_frontpage(viewer, 10)
      refute Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "returns only the latest photo from each user" do
      viewer  = insert(:user)
      album_1   = insert(:photo_album, visibility: "public")
      album_2   = insert(:photo_album, visibility: "public", user: album_1.user)
      photo_1 = insert(:photo, photo_album: album_1)
      photo_2 = insert(:photo, photo_album: album_2)
      photo_3 = insert(:photo, photo_album: album_2)
      photo_4 = insert(:photo)
      photos  = Photo.newest_for_frontpage(viewer, 10)
      refute Enum.find(photos, fn(p) -> p.id == photo_1.id end)
      refute Enum.find(photos, fn(p) -> p.id == photo_2.id end)
      assert Enum.find(photos, fn(p) -> p.id == photo_3.id end)
      assert Enum.find(photos, fn(p) -> p.id == photo_4.id end)
    end

    test "only returns the specified number of photos" do
      viewer = insert(:user)
      insert_list(3, :photo)
      photos = Photo.newest_for_frontpage(viewer, 2)
      assert length(photos) == 2
    end

    test "sorts the photos from newest to oldest" do
      viewer        = insert(:user)
      photo_1       = insert(:photo)
      photo_2       = insert(:photo)
      [first, last] = Photo.newest_for_frontpage(viewer, 2)
      assert first.id == photo_2.id
      assert last.id  == photo_1.id
    end
  end

  describe "chronologically/1" do
    test "it orders older photos before newer ones" do
      expected_first = insert(:photo)
      expected_last  = insert(:photo)
      [first, last] = Photo |> Photo.chronologically() |> Repo.all
      assert first.id == expected_first.id
      assert last.id == expected_last.id
    end
  end

  describe "in_positional_order/1" do
    test "it orders a photo with a lower position value before a photo with a higher position value" do
      expected_last  = insert(:photo, position: 1)
      expected_first = insert(:photo, position: 0)
      [first, last] = Photo |> Photo.in_positional_order() |> Repo.all
      assert first.id == expected_first.id
      assert last.id  == expected_last.id
    end

    test "it orders a photo with a lower inserted_at value before a photo with a higher inserted_at value" do
      expected_last  = insert(:photo, position: 0, inserted_at: Timex.shift(Timex.now, minutes: -1))
      expected_first = insert(:photo, position: 0, inserted_at: Timex.shift(Timex.now, minutes: -2))
      [first, last] = Photo |> Photo.in_positional_order() |> Repo.all
      assert first.id == expected_first.id
      assert last.id  == expected_last.id
    end
  end

  describe "visible_by/2" do
    test "always returns photos from albums that are set to public" do
      user         = insert(:user)
      photo_album  = insert(:photo_album, visibility: "public")
      photo        = insert(:photo, photo_album: photo_album)
      photos       = Photo |> Photo.visible_by(user) |> Repo.all
      ids          = Enum.map photos, fn(c) -> c.id end
      assert [photo.id] == ids
    end

    test "always returns photos from private albums if the user is the same as the user of the photo album" do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user, visibility: "private")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo |> Photo.visible_by(user) |> Repo.all
      ids         = Enum.map photos, fn(c) -> c.id end
      assert [photo.id] == ids
    end

    test "always returns photos from friends_only albums if the user is the same as the user of the photo album" do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user, visibility: "friends_only")
      photo       = insert(:photo, photo_album: photo_album)
      photos      = Photo |> Photo.visible_by(user) |> Repo.all
      ids         = Enum.map photos, fn(c) -> c.id end
      assert [photo.id] == ids
    end

    test "never returns photos from private albums if the user is not the same as the user of the photo album" do
      user        = insert(:user)
      photo_album = insert(:photo_album, visibility: "private")
      _photo      = insert(:photo, photo_album: photo_album)
      photos      = Photo |> Photo.visible_by(user) |> Repo.all
      assert photos == []
    end

    test "never returns photos from friends_only albums if the user is not friends with the user of the photo album" do
      user        = insert(:user)
      photo_album = insert(:photo_album, visibility: "friends_only")
      _photo      = insert(:photo, photo_album: photo_album)
      photos      = Photo |> Photo.visible_by(user) |> Repo.all
      assert photos == []
    end

    test "always returns photos from friends_only albums if the user is befriended by the user of the photo album" do
      author       = insert(:user)
      user         = insert(:user)
      photo_album  = insert(:photo_album, user: author, visibility: "friends_only")
      photo        = insert(:photo, photo_album: photo_album)
      _friendship  = insert(:friendship, sender: author, recipient: user)
      photos       = Photo |> Photo.visible_by(user) |> Repo.all
      ids          = Enum.map photos, fn(c) -> c.id end
      assert [photo.id] == ids
    end

    test "always returns photos from friends_only photo albums if the user of the photo album is befriended by the user" do
      author       = insert(:user)
      user         = insert(:user)
      photo_album  = insert(:photo_album, user: author, visibility: "friends_only")
      photo        = insert(:photo, photo_album: photo_album)
      _friendship  = insert(:friendship, sender: user, recipient: author)
      photos       = Photo |> Photo.visible_by(user) |> Repo.all
      ids          = Enum.map photos, fn(c) -> c.id end
      assert [photo.id] == ids
    end

    test "never returns photos from friends_only albums if the user is pending friendship from the user of the photo album" do
      author      = insert(:user)
      user        = insert(:user)
      photo_album = insert(:photo_album, user: author, visibility: "friends_only")
      _photo      = insert(:photo, photo_album: photo_album)
      _friendship = insert(:friendship_request, sender: author, recipient: user)
      photos      = Photo |> Photo.visible_by(user) |> Repo.all
      assert photos == []
    end

    test "never returns photos from friends_only albums if the user of the photo album is pending friendship from the user" do
      author      = insert(:user)
      user        = insert(:user)
      photo_album = insert(:photo_album, user: author, visibility: "friends_only")
      _photo      = insert(:photo, photo_album: photo_album)
      _friendship = insert(:friendship_request, sender: user, recipient: author)
      photos      = Photo |> Photo.visible_by(user) |> Repo.all
      assert photos == []
    end
  end

  describe "not_private/1" do
    test "returns photos from public albums" do
      album  = insert(:photo_album, visibility: "public")
      photo  = insert(:photo, photo_album: album)
      photos = Photo |> Photo.not_private |> Repo.all
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "returns photos from friends_only albums" do
      album  = insert(:photo_album, visibility: "friends_only")
      photo  = insert(:photo, photo_album: album)
      photos = Photo |> Photo.not_private |> Repo.all
      assert Enum.find(photos, fn(p) -> p.id == photo.id end)
    end

    test "does not return photos from private albums" do
      album  = insert(:photo_album, visibility: "private")
      photo  = insert(:photo, photo_album: album)
      photos = Photo |> Photo.not_private |> Repo.all
      refute Enum.find(photos, fn(p) -> p.id == photo.id end)
    end
  end

  describe "by/2" do
    test "only returns photos from albums owned by the specified user" do
      album1 = insert(:photo_album)
      photo1 = insert(:photo, photo_album: album1)
      album2 = insert(:photo_album)
      photo2 = insert(:photo, photo_album: album2)
      photos = Photo |> Photo.by(album1.user) |> Repo.all
      assert Enum.find(photos, fn(p) -> p.id == photo1.id end)
      refute Enum.find(photos, fn(p) -> p.id == photo2.id end)
    end
  end

  describe "total_used_space_by/1" do
    test "it returns the sum of the file_size of all photos uploaded by the user" do
      user = insert(:user)
      insert(:photo, file_size: 100, photo_album: insert(:photo_album, user: user))
      insert(:photo, file_size: 200, photo_album: insert(:photo_album, user: user))
      insert(:photo, file_size: 400, photo_album: insert(:photo_album, user: user))
      insert(:photo, file_size: 800)
      assert Photo.total_used_space_by(user) == 700
    end

    test "it returns zero if the user has not uploaded any photos" do
      user = insert(:user)
      insert(:photo, file_size: 100)
      assert Photo.total_used_space_by(user) == 0
    end
  end

  describe "delete!/1" do
    test "it deletes the photo entry from the database" do
      {:ok, photo} = Repo.insert(new_changeset(@valid_attrs))
      Photo.delete! photo
      refute Repo.get(Photo, photo.id)
    end

    test "it removes the actual photo file" do
      {:ok, photo} = Repo.insert(new_changeset(@valid_attrs))
      path = "#{File.cwd!}/uploads/photos/#{photo.uuid}/original.jpg"
      assert File.exists? path
      Photo.delete! photo
      refute File.exists? path
    end
  end

  describe "previous/1" do
    test "returns the previous photo in the same album by position" do
      album      = insert(:photo_album)
      photo1     = insert(:photo, position: 1, photo_album: album)
      photo2     = insert(:photo, position: 2, photo_album: album)
      _photo3    = insert(:photo, position: 3, photo_album: album)
      prev_photo = Photo.previous(photo2)
      assert prev_photo.id == photo1.id
    end

    test "returns the previous photo in the same album by inserted_at if another photo with the same position exists" do
      album      = insert(:photo_album)
      _photo1    = insert(:photo, position: 1, photo_album: album)
      photo2     = insert(:photo, position: 2, photo_album: album)
      photo3     = insert(:photo, position: 2, photo_album: album)
      prev_photo = Photo.previous(photo3)
      assert prev_photo.id == photo2.id
    end

    test "returns nil if there are no previous photos in the same album" do
      photo1     = insert(:photo, position: 1)
      prev_photo = Photo.previous(photo1)
      refute prev_photo
    end

    test "does not return photos from other albums" do
      _photo1    = insert(:photo, position: 1)
      photo2     = insert(:photo, position: 2)
      prev_photo = Photo.previous(photo2)
      refute prev_photo
    end
  end

  describe "next/1" do
    test "returns the next photo in the same album by position" do
      album      = insert(:photo_album)
      _photo1    = insert(:photo, position: 1, photo_album: album)
      photo2     = insert(:photo, position: 2, photo_album: album)
      photo3     = insert(:photo, position: 3, photo_album: album)
      next_photo = Photo.next(photo2)
      assert next_photo.id == photo3.id
    end

    test "returns the next photo in the same album by inserted_at if another photo with the same position exists" do
      album      = insert(:photo_album)
      photo1     = insert(:photo, position: 1, photo_album: album)
      photo2     = insert(:photo, position: 1, photo_album: album)
      _photo3    = insert(:photo, position: 2, photo_album: album)
      next_photo = Photo.next(photo1)
      assert next_photo.id == photo2.id
    end

    test "returns nil if there are no next photos in the same album" do
      photo1     = insert(:photo, position: 1)
      next_photo = Photo.next(photo1)
      refute next_photo
    end

    test "does not return photos from other albums" do
      photo1     = insert(:photo, position: 1)
      _photo2    = insert(:photo, position: 2)
      next_photo = Photo.next(photo1)
      refute next_photo
    end
  end

  def new_changeset(attrs \\ %{}, photo_album \\ insert(:photo_album)) do
    photo_album |> Ecto.build_assoc(:photos) |> Photo.changeset(attrs)
  end
end
