defmodule Helheim.VisitorLogEntryTest do
  use Helheim.DataCase
  alias Helheim.Repo
  alias Helheim.VisitorLogEntry

  describe "newest/1" do
    test "it orders recently updated entries before older ones" do
      entry1 = insert(:visitor_log_entry, updated_at: Timex.shift(Timex.now, minutes: 5))
      entry2 = insert(:visitor_log_entry)
      [first, last] = VisitorLogEntry |> VisitorLogEntry.newest |> Repo.all
      assert first.id == entry1.id
      assert last.id  == entry2.id
    end
  end

  describe "track!/2" do
    setup [:create_user]

    test "it successfully tracks a view on a blog post and increments the visitor_count", %{user: user} do
      blog_post              = insert(:blog_post)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, blog_post)
      assert entry.user_id      == user.id
      assert entry.blog_post_id == blog_post.id
      assert Repo.get(Helheim.BlogPost, blog_post.id).visitor_count == 1
    end

    test "it successfully updates an existing view on a blog post and doesn't increment the visitor_count when the last entry was less than 30 minutes ago", %{user: user} do
      blog_post              = insert(:blog_post)
      original_entry         = insert(:visitor_log_entry, user: user, blog_post: blog_post)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, blog_post)
      assert entry.id           == original_entry.id
      refute entry.updated_at   == original_entry.updated_at
      assert entry.user_id      == user.id
      assert entry.blog_post_id == blog_post.id
      assert Repo.get(Helheim.BlogPost, blog_post.id).visitor_count == 0
    end

    test "it does increment the visitor_count when the last entry for a blog post was more than 30 minutes ago", %{user: user} do
      blog_post       = insert(:blog_post)
      _original_entry = insert(:visitor_log_entry, user: user, blog_post: blog_post, updated_at: Timex.shift(Timex.now, minutes: -31))
      {:ok, _}        = VisitorLogEntry.track!(user, blog_post)
      assert Repo.get(Helheim.BlogPost, blog_post.id).visitor_count == 1
    end

    test "it never tracks a view or increments visitor_count on a blog_post belonging to the user", %{user: user} do
      blog_post   = insert(:blog_post, user: user)
      {:error, _} = VisitorLogEntry.track!(user, blog_post)
      refute Repo.one(VisitorLogEntry)
      assert Repo.get(Helheim.BlogPost, blog_post.id).visitor_count == 0
    end

    test "it successfully tracks a view on a photo album and increments the visitor_count", %{user: user} do
      photo_album            = insert(:photo_album)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, photo_album)
      assert entry.user_id        == user.id
      assert entry.photo_album_id == photo_album.id
      assert Repo.get(Helheim.PhotoAlbum, photo_album.id).visitor_count == 1
    end

    test "it successfully updates an existing view on a photo album and doesn't increment the visitor_count when the last entry was less than 30 minutes ago", %{user: user} do
      photo_album            = insert(:photo_album)
      original_entry         = insert(:visitor_log_entry, user: user, photo_album: photo_album)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, photo_album)
      assert entry.id             == original_entry.id
      refute entry.updated_at     == original_entry.updated_at
      assert entry.user_id        == user.id
      assert entry.photo_album_id == photo_album.id
      assert Repo.get(Helheim.PhotoAlbum, photo_album.id).visitor_count == 0
    end

    test "it does increment the visitor_count when the last entry for a photo album was more than 30 minutes ago", %{user: user} do
      photo_album     = insert(:photo_album)
      _original_entry = insert(:visitor_log_entry, user: user, photo_album: photo_album, updated_at: Timex.shift(Timex.now, minutes: -31))
      {:ok, _}        = VisitorLogEntry.track!(user, photo_album)
      assert Repo.get(Helheim.PhotoAlbum, photo_album.id).visitor_count == 1
    end

    test "it never tracks a view or increments visitor_count on a photo_album belonging to the user", %{user: user} do
      photo_album = insert(:photo_album, user: user)
      {:error, _} = VisitorLogEntry.track!(user, photo_album)
      refute Repo.one(VisitorLogEntry)
      assert Repo.get(Helheim.PhotoAlbum, photo_album.id).visitor_count == 0
    end

    test "it successfully tracks a view on a photo and increments the visitor_count", %{user: user} do
      photo                  = insert(:photo)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, photo)
      assert entry.user_id  == user.id
      assert entry.photo_id == photo.id
      assert Repo.get(Helheim.Photo, photo.id).visitor_count == 1
    end

    test "it successfully updates an existing view on a photo and doesn't increment the visitor_count when the last entry was less than 30 minutes ago", %{user: user} do
      photo                  = insert(:photo)
      original_entry         = insert(:visitor_log_entry, user: user, photo: photo)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, photo)
      assert entry.id         == original_entry.id
      refute entry.updated_at == original_entry.updated_at
      assert entry.user_id    == user.id
      assert entry.photo_id   == photo.id
      assert Repo.get(Helheim.Photo, photo.id).visitor_count == 0
    end

    test "it does increment the visitor_count when the last entry for a photo was more than 30 minutes ago", %{user: user} do
      photo           = insert(:photo)
      _original_entry = insert(:visitor_log_entry, user: user, photo: photo, updated_at: Timex.shift(Timex.now, minutes: -31))
      {:ok, _}        = VisitorLogEntry.track!(user, photo)
      assert Repo.get(Helheim.Photo, photo.id).visitor_count == 1
    end

    test "it never tracks a view or increments visitor_count on a photo belonging to the user", %{user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      {:error, _} = VisitorLogEntry.track!(user, photo)
      refute Repo.one(VisitorLogEntry)
      assert Repo.get(Helheim.Photo, photo.id).visitor_count == 0
    end

    test "it successfully tracks a view on a profile and increments the visitor_count", %{user: user} do
      profile                = insert(:user)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, profile)
      assert entry.user_id    == user.id
      assert entry.profile_id == profile.id
      assert Repo.get(Helheim.User, profile.id).visitor_count == 1
    end

    test "it successfully updates an existing view on a profile and doesn't increment the visitor_count when the last entry was less than 30 minutes ago", %{user: user} do
      profile                = insert(:user)
      original_entry         = insert(:visitor_log_entry, user: user, profile: profile)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, profile)
      assert entry.id         == original_entry.id
      refute entry.updated_at == original_entry.updated_at
      assert entry.user_id    == user.id
      assert entry.profile_id == profile.id
      assert Repo.get(Helheim.User, profile.id).visitor_count == 0
    end

    test "it does increment the visitor_count when the last entry for a profile was more than 30 minutes ago", %{user: user} do
      profile         = insert(:user)
      _original_entry = insert(:visitor_log_entry, user: user, profile: profile, updated_at: Timex.shift(Timex.now, minutes: -31))
      {:ok, _}        = VisitorLogEntry.track!(user, profile)
      assert Repo.get(Helheim.User, profile.id).visitor_count == 1
    end

    test "it never tracks a view or increments visitor_count on a profile belonging to the user", %{user: user} do
      {:error, _} = VisitorLogEntry.track!(user, user)
      refute Repo.one(VisitorLogEntry)
      assert Repo.get(Helheim.User, user.id).visitor_count == 0
    end

    test "it allows the user to have multiple different entries for different subjects", %{user: user} do
      blog_post              = insert(:blog_post)
      photo_album            = insert(:photo_album)
      original_entry         = insert(:visitor_log_entry, user: user, blog_post: blog_post)
      {:ok, %{entry: entry}} = VisitorLogEntry.track!(user, photo_album)
      refute entry.id             == original_entry.id
      assert entry.user_id        == user.id
      assert entry.photo_album_id == photo_album.id
    end
  end
end
