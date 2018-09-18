defmodule Helheim.CommentTest do
  use Helheim.DataCase

  alias Helheim.Comment

  describe "not_deleted/1" do
    test "only returns comments where deleted_at is null" do
      comment1 = insert(:blog_post_comment, deleted_at: nil)
      comment2 = insert(:blog_post_comment, deleted_at: Timex.now)
      comments = Comment |> Comment.not_deleted |> Repo.all
      ids      = Enum.map comments, fn(c) -> c.id end
      assert Enum.member?(ids, comment1.id)
      refute Enum.member?(ids, comment2.id)
    end
  end

  describe "deletable_by/2" do
    test "returns true if the specified user is an admin regardless of the type of comment" do
      comment1 = insert(:blog_post_comment)
      comment2 = insert(:profile_comment)
      comment3 = insert(:photo_comment)
      user     = insert(:user, role: "admin")
      assert Comment.deletable_by?(comment1, user)
      assert Comment.deletable_by?(comment2, user)
      assert Comment.deletable_by?(comment3, user)
    end

    test "returns true if the specified user is a mod regardless of the type of comment" do
      comment1 = insert(:blog_post_comment)
      comment2 = insert(:profile_comment)
      comment3 = insert(:photo_comment)
      user     = insert(:user, role: "mod")
      assert Comment.deletable_by?(comment1, user)
      assert Comment.deletable_by?(comment2, user)
      assert Comment.deletable_by?(comment3, user)
    end

    test "returns true if the specified comment is a profile comment and the specified user is the same as the profile of the comment" do
      comment = insert(:profile_comment)
      user1   = comment.profile
      user2   = insert(:user)
      assert Comment.deletable_by?(comment, user1)
      refute Comment.deletable_by?(comment, user2)
    end

    test "returns true if the specified comment is a blog post comment and the specified user is the author of the blog post" do
      comment = insert(:blog_post_comment)
      user1   = comment.blog_post.user
      user2   = insert(:user)
      assert Comment.deletable_by?(comment, user1)
      refute Comment.deletable_by?(comment, user2)
    end

    test "returns true if the specified comment is a photo comment and the specified user is the author of the photo" do
      comment = insert(:photo_comment)
      user1   = comment.photo.photo_album.user
      user2   = insert(:user)
      assert Comment.deletable_by?(comment, user1)
      refute Comment.deletable_by?(comment, user2)
    end

    test "returns false in all other cases" do
      comment1 = insert(:blog_post_comment)
      comment2 = insert(:profile_comment)
      comment3 = insert(:photo_comment)
      user     = insert(:user)
      refute Comment.deletable_by?(comment1, user)
      refute Comment.deletable_by?(comment2, user)
      refute Comment.deletable_by?(comment3, user)
    end
  end

  describe "editable_by?/2" do
    test "it returns true if the user is the author of the comment and it is no older than 60 minutes" do
      user    = insert(:user)
      comment = insert(:profile_comment, author: user, inserted_at: Timex.shift(Timex.now, minutes: -59))
      assert Comment.editable_by?(comment, user)
    end

    test "it returns false if the comment is older than 60 minutes" do
      user    = insert(:user)
      comment = insert(:profile_comment, author: user, inserted_at: Timex.shift(Timex.now, minutes: -61))
      refute Comment.editable_by?(comment, user)
    end

    test "it returns false if the user is not the author of the comment" do
      user    = insert(:user)
      comment = insert(:profile_comment, inserted_at: Timex.shift(Timex.now, minutes: -9))
      refute Comment.editable_by?(comment, user)
    end

    test "it returns true if the user is an admin" do
      user    = insert(:user, role: "admin")
      comment = insert(:profile_comment, inserted_at: Timex.shift(Timex.now, minutes: -11))
      assert Comment.editable_by?(comment, user)
    end

    test "it returns true if the user is a mod" do
      user    = insert(:user, role: "mod")
      comment = insert(:profile_comment, inserted_at: Timex.shift(Timex.now, minutes: -11))
      assert Comment.editable_by?(comment, user)
    end
  end
end
