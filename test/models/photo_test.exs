defmodule Helheim.PhotoTest do
  use Helheim.ModelCase
  import Mock
  alias Helheim.Repo
  alias Helheim.Photo

  @valid_upload %Plug.Upload{path: "test/files/1.0MB.jpg", filename: "1.0MB.jpg"}
  @valid_attrs %{title: "Cool Photo", file: @valid_upload}

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

    test_with_mock "does not allow uploading files bigger than the total space left for the user",
      Helheim.Photo, [:passthrough], [max_total_file_size_per_user: fn() -> 0.9 * 1000 * 1000 end] do
      changeset = new_changeset @valid_attrs
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

  describe "newest_public_photos_by/2" do
    test "it returns the n newest public photos uploaded by the specified user" do
      user = insert(:user)
      expected_last = insert(:photo, photo_album: insert(:photo_album, user: user))
      insert(:photo, photo_album: insert(:photo_album, user: user, visibility: "friends_only"))
      expected_first = insert(:photo, photo_album: insert(:photo_album, user: user))
      insert(:photo)
      [first, last] = Photo.newest_public_photos_by(user, 2)
      assert first.id == expected_first.id
      assert last.id == expected_last.id
    end
  end

  describe "newest_public_photos/1" do
    test "it returns the n newest public photos" do
      insert(:photo)
      expected_last = insert(:photo)
      insert(:photo, photo_album: insert(:photo_album, visibility: "friends_only"))
      expected_first = insert(:photo)
      [first, last] = Photo.newest_public_photos(2)
      assert first.id == expected_first.id
      assert last.id == expected_last.id
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

  def new_changeset(attrs \\ %{}) do
    photo_album = insert(:photo_album)
    photo_album |> Ecto.build_assoc(:photos) |> Photo.changeset(attrs)
  end
end
