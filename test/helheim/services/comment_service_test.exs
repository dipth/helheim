defmodule Helheim.CommentServiceTest do
  use Helheim.DataCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.CommentService
  alias Helheim.Comment
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Photo
  alias Helheim.CalendarEvent
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
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(profile, author, @valid_body)

      assert_called_with_pattern NotificationService, :create_async!, fn(args) ->
        profile_id = profile.id
        author_id  = author.id
        [_repo, _changes, "comment", %User{id: ^profile_id}, %User{id: ^author_id}] = args
      end
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
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

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
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(blog_post, author, @valid_body)

      assert_called_with_pattern NotificationService, :create_async!, fn(args) ->
        blog_post_id = blog_post.id
        author_id    = author.id
        [_repo, _changes, "comment", %BlogPost{id: ^blog_post_id}, %User{id: ^author_id}] = args
      end
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
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

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
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(photo, author, @valid_body)

      assert_called_with_pattern NotificationService, :create_async!, fn(args) ->
        photo_id  = photo.id
        author_id = author.id
        [_repo, _changes, "comment", %Photo{id: ^photo_id}, %User{id: ^author_id}] = args
      end
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
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

      CommentService.create!(photo, author, @invalid_body)
    end
  end

  ##############################################################################
  # create!/3 for a calendar_event
  describe "create/3 for a calendar_event with valid author and body" do
    setup [:create_author, :create_calendar_event]

    test "creates a comment on the calendar_event from the author with the specified body", %{author: author, calendar_event: calendar_event} do
      {:ok, %{comment: comment}} = CommentService.create!(calendar_event, author, @valid_body)
      assert comment.author_id         == author.id
      assert comment.calendar_event_id == calendar_event.id
      assert comment.body              == @valid_body
    end

    test "increments the comment_count of the calendar_event", %{author: author, calendar_event: calendar_event} do
      CommentService.create!(calendar_event, author, @valid_body)
      calendar_event = Repo.get(CalendarEvent, calendar_event.id)
      assert calendar_event.comment_count == 1
    end

    test_with_mock "triggers notifications", %{author: author, calendar_event: calendar_event},
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      CommentService.create!(calendar_event, author, @valid_body)

      assert_called_with_pattern NotificationService, :create_async!, fn(args) ->
        calendar_event_id = calendar_event.id
        author_id         = author.id
        [_repo, _changes, "comment", %CalendarEvent{id: ^calendar_event_id}, %User{id: ^author_id}] = args
      end
    end
  end

  describe "create/3 for a calendar_event with invalid body" do
    setup [:create_author, :create_calendar_event]

    test "does not create any comments", %{author: author, calendar_event: calendar_event} do
      CommentService.create!(calendar_event, author, @invalid_body)
      refute Repo.one(Comment)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{author: author, calendar_event: calendar_event} do
      {:error, failed_operation, failed_value, changes_so_far} = CommentService.create!(calendar_event, author, @invalid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end

    test "does not increment the comment_count of the calendar_event", %{author: author, calendar_event: calendar_event} do
      CommentService.create!(calendar_event, author, @invalid_body)
      calendar_event = Repo.get(CalendarEvent, calendar_event.id)
      assert calendar_event.comment_count == 0
    end

    test_with_mock "does not trigger notifications", %{author: author, calendar_event: calendar_event},
      NotificationService, [], [create_async!: fn(_repo, _changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

      CommentService.create!(calendar_event, author, @invalid_body)
    end
  end

  ##############################################################################
  # delete!/3
  describe "delete/3" do
    setup [:create_user, :create_comment]

    test_with_mock "marks the comment as deleted with the specified reason if it is deletable by the user", %{user: user, comment: comment},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> true end] do

      comment = Comment |> Comment.with_preloads |> Repo.get(comment.id)
      {:ok, %{comment: comment}} = CommentService.delete!(comment, user, "foo bar")
      {:ok, time_diff, _, _}     = Calendar.DateTime.diff(comment.deleted_at, DateTime.utc_now)

      assert comment.deleter_id      == user.id
      assert comment.deletion_reason == "foo bar"
      assert time_diff < 10
    end

    test_with_mock "decrements the comment count of the commentable if it is deletable by the user", %{user: user},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> true end] do

      blog_post = insert :blog_post, comment_count: 1
      comment   = insert :blog_post_comment, blog_post: blog_post
      comment   = Comment |> Comment.with_preloads |> Repo.get(comment.id)

      {:ok, %{comment: _comment}} = CommentService.delete!(comment, user, "foo bar")

      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.comment_count == 0
    end

    test_with_mock "does not mark the comment as deleted if it is not deletable by the user", %{user: user, comment: comment},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> false end] do

      comment = Comment |> Comment.with_preloads |> Repo.get(comment.id)
      {:error, _, _, _} = CommentService.delete!(comment, user, "foo bar")
      comment           = Repo.get(Comment, comment.id)

      refute comment.deleter_id
      refute comment.deletion_reason
      refute comment.deleted_at
    end

    test_with_mock "does not decrement the comment count of the commentable if it is not deletable by the user", %{user: user},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> false end] do

      blog_post = insert :blog_post, comment_count: 1
      comment   = insert :blog_post_comment, blog_post: blog_post

      comment = Comment |> Comment.with_preloads |> Repo.get(comment.id)
      {:error, _, _, _} = CommentService.delete!(comment, user, "foo bar")

      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.comment_count == 1
    end
  end

  ##############################################################################
  # delete!/2
  describe "delete/2" do
    setup [:create_user, :create_comment]

    test_with_mock "marks the comment as deleted with a blank reason if it is deletable by the user", %{user: user, comment: comment},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> true end] do

      comment = Comment |> Comment.with_preloads |> Repo.get(comment.id)
      {:ok, %{comment: comment}} = CommentService.delete!(comment, user)
      {:ok, time_diff, _, _}     = Calendar.DateTime.diff(comment.deleted_at, DateTime.utc_now)

      assert comment.deleter_id == user.id
      refute comment.deletion_reason
      assert time_diff < 10
    end

    test_with_mock "decrements the comment count of the commentable if it is deletable by the user", %{user: user},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> true end] do

      blog_post = insert :blog_post, comment_count: 1
      comment   = insert :blog_post_comment, blog_post: blog_post
      comment   = Comment |> Comment.with_preloads |> Repo.get(comment.id)

      {:ok, %{comment: _comment}} = CommentService.delete!(comment, user)

      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.comment_count == 0
    end

    test_with_mock "does not mark the comment as deleted if it is not deletable by the user", %{user: user, comment: comment},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> false end] do

      comment = Comment |> Comment.with_preloads |> Repo.get(comment.id)
      {:error, _, _, _} = CommentService.delete!(comment, user)
      comment           = Repo.get(Comment, comment.id)

      refute comment.deleter_id
      refute comment.deletion_reason
      refute comment.deleted_at
    end

    test_with_mock "does not decrement the comment count of the commentable if it is not deletable by the user", %{user: user},
      Comment, [:passthrough], [deletable_by?: fn(_comment, _user) -> false end] do

      blog_post = insert :blog_post, comment_count: 1
      comment   = insert :blog_post_comment, blog_post: blog_post

      comment = Comment |> Comment.with_preloads |> Repo.get(comment.id)
      {:error, _, _, _} = CommentService.delete!(comment, user)

      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.comment_count == 1
    end
  end

  ##############################################################################
  # SETUP
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

  defp create_calendar_event(_context) do
    calendar_event = insert(:calendar_event)
    [calendar_event: calendar_event]
  end

  defp create_comment(_context) do
    comment = insert(:blog_post_comment)
    [comment: comment]
  end
end
