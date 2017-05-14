defmodule Helheim.CommentServiceTest do
  use Helheim.ModelCase
  import Mock
  alias Helheim.CommentService
  alias Helheim.Comment
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Photo
  alias Helheim.NotificationService

  @valid_body "My Comment"
  @invalid_body ""

  ##############################################################################
  # create!/3 for a profile
  describe "create/3 for a profile with valid author and body" do
    setup [:create_author, :create_profile]

    test "creates a comment on the profile from the author with the specified body", %{author: author, profile: profile} do
      {:ok, %{comment: comment}} = CommentService.create!(profile, author, @valid_body)
      assert comment.author_id  == author.id
      assert comment.profile_id == profile.id
      assert comment.body       == @valid_body
    end

    test "increments the comment_count of the profile", %{author: author, profile: profile} do
      CommentService.create!(profile, author, @valid_body)
      profile = Repo.get(User, profile.id)
      assert profile.comment_count == 1
    end

    test_with_mock "triggers notifications", %{author: author, profile: profile},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(profile, author, @valid_body)
      assert called NotificationService.create_async!(:_, "comment", profile, author)
    end
  end

  describe "create/3 for a profile with invalid body" do
    setup [:create_author, :create_profile]

    test "does not create any comments", %{author: author, profile: profile} do
      CommentService.create!(profile, author, @invalid_body)
      refute Repo.one(Comment)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{author: author, profile: profile} do
      {:error, failed_operation, failed_value, changes_so_far} = CommentService.create!(profile, author, @invalid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end

    test "does not increment the comment_count of the profile", %{author: author, profile: profile} do
      CommentService.create!(profile, author, @invalid_body)
      profile = Repo.get(User, profile.id)
      assert profile.comment_count == 0
    end

    test_with_mock "does not trigger notifications", %{author: author, profile: profile},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

      CommentService.create!(profile, author, @invalid_body)
    end
  end

  ##############################################################################
  # create!/3 for a blog post
  describe "create/3 for a blog post with valid author and body" do
    setup [:create_author, :create_blog_post]

    test "creates a comment on the profile from the author with the specified body", %{author: author, blog_post: blog_post} do
      {:ok, %{comment: comment}} = CommentService.create!(blog_post, author, @valid_body)
      assert comment.author_id    == author.id
      assert comment.blog_post_id == blog_post.id
      assert comment.body         == @valid_body
    end

    test "increments the comment_count of the blog post", %{author: author, blog_post: blog_post} do
      CommentService.create!(blog_post, author, @valid_body)
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.comment_count == 1
    end

    test_with_mock "triggers notifications", %{author: author, blog_post: blog_post},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(blog_post, author, @valid_body)
      assert called NotificationService.create_async!(:_, "comment", blog_post, author)
    end
  end

  describe "create/3 for a blog post with invalid body" do
    setup [:create_author, :create_blog_post]

    test "does not create any comments", %{author: author, blog_post: blog_post} do
      CommentService.create!(blog_post, author, @invalid_body)
      refute Repo.one(Comment)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{author: author, blog_post: blog_post} do
      {:error, failed_operation, failed_value, changes_so_far} = CommentService.create!(blog_post, author, @invalid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end

    test "does not increment the comment_count of the blog post", %{author: author, blog_post: blog_post} do
      CommentService.create!(blog_post, author, @invalid_body)
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.comment_count == 0
    end

    test_with_mock "does not trigger notifications", %{author: author, blog_post: blog_post},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

      CommentService.create!(blog_post, author, @invalid_body)
    end
  end

  ##############################################################################
  # create!/3 for a photo
  describe "create/3 for a photo with valid author and body" do
    setup [:create_author, :create_photo]

    test "creates a comment on the photo from the author with the specified body", %{author: author, photo: photo} do
      {:ok, %{comment: comment}} = CommentService.create!(photo, author, @valid_body)
      assert comment.author_id == author.id
      assert comment.photo_id  == photo.id
      assert comment.body      == @valid_body
    end

    test "increments the comment_count of the photo", %{author: author, photo: photo} do
      CommentService.create!(photo, author, @valid_body)
      photo = Repo.get(Photo, photo.id)
      assert photo.comment_count == 1
    end

    test_with_mock "triggers notifications", %{author: author, photo: photo},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(photo, author, @valid_body)
      assert called NotificationService.create_async!(:_, "comment", photo, author)
    end
  end

  describe "create/3 for a photo with invalid body" do
    setup [:create_author, :create_photo]

    test "does not create any comments", %{author: author, photo: photo} do
      CommentService.create!(photo, author, @invalid_body)
      refute Repo.one(Comment)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{author: author, photo: photo} do
      {:error, failed_operation, failed_value, changes_so_far} = CommentService.create!(photo, author, @invalid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end

    test "does not increment the comment_count of the photo", %{author: author, photo: photo} do
      CommentService.create!(photo, author, @invalid_body)
      photo = Repo.get(Photo, photo.id)
      assert photo.comment_count == 0
    end

    test_with_mock "does not trigger notifications", %{author: author, photo: photo},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

      CommentService.create!(photo, author, @invalid_body)
    end
  end

  defp create_author(_context) do
    author = insert(:user)
    [author: author]
  end

  defp create_profile(_context) do
    profile = insert(:user)
    [profile: profile]
  end

  defp create_blog_post(_context) do
    blog_post = insert(:blog_post)
    [blog_post: blog_post]
  end

  defp create_photo(_context) do
    photo = insert(:photo)
    [photo: photo]
  end
end