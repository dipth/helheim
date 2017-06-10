defmodule Helheim.CommentControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.CommentService
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Photo

  @comment_attrs %{body: "My Comment"}

  ##############################################################################
  # index/2 for a profile
  describe "index/2 for a profile when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successfull response", %{conn: conn} do
      profile = insert(:user)
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert html_response(conn, 200)
    end

    test "it only shows comments for the specified profile", %{conn: conn} do
      comment_1 = insert(:profile_comment, body: "Comment 1")
      comment_2 = insert(:profile_comment, body: "Comment 2")
      profile = comment_1.profile
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert conn.resp_body =~ comment_1.body
      refute conn.resp_body =~ comment_2.body
    end

    test "it supports showing comments where the author is deleted", %{conn: conn} do
      comment = insert(:profile_comment, author: nil, body: "Comment with deleted user")
      profile = comment.profile
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert html_response(conn, 200) =~ "Comment with deleted user"
    end

    test "it redirects to an error page when supplying an non-existing profile id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/1/comments"
      end
    end

    test "it redirects to a block page when the specified profile is blocking the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      conn  = get conn, "/profiles/#{block.blocker.id}/comments"
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end

    test "does not show deleted comments", %{conn: conn} do
      comment = insert(:profile_comment, deleted_at: DateTime.utc_now, body: "This is a deleted comment")
      profile = comment.profile
      conn    = get conn, "/profiles/#{profile.id}/comments"
      refute html_response(conn, 200) =~ "This is a deleted comment"
    end
  end

  describe "index/2 for a profile when not signed in" do
    test "it redirects to the login page", %{conn: conn} do
      profile = insert(:user)
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2 for a profile
  describe "create/2 for a profile when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it redirects to the profile comments page with a success flash message when successfull", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> {:ok, %{comment: %{}}} end] do

      profile = Repo.get(User, insert(:user).id)
      conn    = post conn, "/profiles/#{profile.id}/comments", comment: @comment_attrs
      assert called CommentService.create!(profile, user, @comment_attrs[:body])
      assert redirected_to(conn)       == public_profile_comment_path(conn, :index, profile.id)
      assert get_flash(conn, :success) == gettext("Comment created successfully")
    end

    test_with_mock "it redirects to the profile comments page with an error flash message when unsuccessfull", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> {:error, :comment, %{}, []} end] do

      profile = Repo.get(User, insert(:user).id)
      conn    = post conn, "/profiles/#{profile.id}/comments", comment: @comment_attrs
      assert called CommentService.create!(profile, user, @comment_attrs[:body])
      assert redirected_to(conn)     == public_profile_comment_path(conn, :index, profile.id)
      assert get_flash(conn, :error) == gettext("Unable to create comment")
    end

    test_with_mock "it does not invoke the CommentService if the profile does not exist but instead shows a 404 error", %{conn: conn},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/profiles/1/comments", comment: @comment_attrs
      end
    end

    test_with_mock "it does not invoke the CommentService if the profile is blocking the current user but instead redirects to a block page", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      block = insert(:block, blockee: user)
      conn  = post conn, "/profiles/#{block.blocker.id}/comments", comment: @comment_attrs
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end
  end

  describe "create/2 for a profile when not signed in" do
    test_with_mock "it does not invoke the CommentService", %{conn: conn},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      profile = insert(:user)
      post conn, "/profiles/#{profile.id}/comments", comment: @comment_attrs
    end

    test "it redirects to the login page", %{conn: conn} do
      profile = insert(:user)
      conn    = post conn, "/profiles/#{profile.id}/comments", comment: @comment_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2 for a blog post
  describe "create/2 for a blog post when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it redirects to the blog post page with a success flash message when successfull", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> {:ok, %{comment: %{}}} end] do

      blog_post = BlogPost |> preload(:user) |> Repo.get!(insert(:blog_post).id)
      conn      = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @comment_attrs
      assert called CommentService.create!(blog_post, user, @comment_attrs[:body])
      assert redirected_to(conn)       == public_profile_blog_post_path(conn, :show, blog_post.user, blog_post)
      assert get_flash(conn, :success) == gettext("Comment created successfully")
    end

    test_with_mock "it redirects to the blog post page with an error flash message when unsuccessfull", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> {:error, :comment, %{}, []} end] do

      blog_post = BlogPost |> preload(:user) |> Repo.get!(insert(:blog_post).id)
      conn      = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @comment_attrs
      assert called CommentService.create!(blog_post, user, @comment_attrs[:body])
      assert redirected_to(conn)     == public_profile_blog_post_path(conn, :show, blog_post.user, blog_post)
      assert get_flash(conn, :error) == gettext("Unable to create comment")
    end

    test_with_mock "it does not invoke the CommentService if the blog post does not exist but instead shows a 404 error", %{conn: conn},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/blog_posts/1/comments", comment: @comment_attrs
      end
    end

    test_with_mock "it does not invoke the CommentService if the author of the blog is blocking the current user but instead redirects to a block page", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      block     = insert(:block, blockee: user)
      blog_post = insert(:blog_post, user: block.blocker)
      conn      = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @comment_attrs
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end
  end

  describe "create/2 for a blog post when not signed in" do
    test_with_mock "it does not invoke the CommentService", %{conn: conn},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      blog_post = insert(:blog_post)
      post conn, "/blog_posts/#{blog_post.id}/comments", comment: @comment_attrs
    end

    test "it redirects to the login page", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn      = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @comment_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2 for a photo
  describe "create/2 for a photo when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it redirects to the photo page with a success flash message when successfull", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> {:ok, %{comment: %{}}} end] do

      photo = Photo |> preload(photo_album: :user) |> Repo.get!(insert(:photo).id)
      conn  = post conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/comments", comment: @comment_attrs
      assert called CommentService.create!(photo, user, @comment_attrs[:body])
      assert redirected_to(conn)       == public_profile_photo_album_photo_path(conn, :show, photo.photo_album.user_id, photo.photo_album.id, photo)
      assert get_flash(conn, :success) == gettext("Comment created successfully")
    end

    test_with_mock "it redirects to the photo page with an error flash message when unsuccessfull", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> {:error, :comment, %{}, []} end] do

      photo = Photo |> preload(photo_album: :user) |> Repo.get!(insert(:photo).id)
      conn  = post conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/comments", comment: @comment_attrs
      assert called CommentService.create!(photo, user, @comment_attrs[:body])
      assert redirected_to(conn)     == public_profile_photo_album_photo_path(conn, :show, photo.photo_album.user_id, photo.photo_album.id, photo)
      assert get_flash(conn, :error) == gettext("Unable to create comment")
    end

    test_with_mock "it does not invoke the CommentService if the photo does not exist but instead shows a 404 error", %{conn: conn},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/photo_albums/1/photos/1/comments", comment: @comment_attrs
      end
    end

    test_with_mock "it does not invoke the CommentService if the author of the photo is blocking the current user but instead redirects to a block page", %{conn: conn, user: user},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      block       = insert(:block, blockee: user)
      photo_album = insert(:photo_album, user: block.blocker)
      photo       = insert(:photo, photo_album: photo_album)
      conn        = post conn, "/photo_albums/#{photo_album.id}/photos/#{photo.id}/comments", comment: @comment_attrs
      assert redirected_to(conn) == public_profile_block_path(conn, :show, block.blocker)
    end
  end

  describe "create/2 for a photo when not signed in" do
    test_with_mock "it does not invoke the CommentService", %{conn: conn},
      CommentService, [], [create!: fn(_commentable, _author, _body) -> raise("CommentService was called!") end] do

      photo = insert(:photo)
      post conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/comments", comment: @comment_attrs
    end

    test "it redirects to the login page", %{conn: conn} do
      photo = insert(:photo)
      conn  = post conn, "/photo_albums/#{photo.photo_album_id}/photos/#{photo.id}/comments", comment: @comment_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it returns a successfull response when the comment could be deleted", %{conn: conn},
      CommentService, [], [delete!: fn(_comment, _user) -> {:ok, %{comment: %{}}} end] do

      comment = insert(:blog_post_comment)
      conn = delete conn, "/comments/#{comment.id}"
      assert response(conn, 200)
    end

    test_with_mock "it returns a 401 response when the comment could not be deleted", %{conn: conn},
      CommentService, [], [delete!: fn(_comment, _user) -> {:error, nil, nil, nil} end] do

      comment = insert(:blog_post_comment)
      conn = delete conn, "/comments/#{comment.id}"
      assert response(conn, 401)
    end

    test_with_mock "it does not invoke the CommentService and instead shows an error page when the comment does not exist", %{conn: conn},
      CommentService, [], [delete!: fn(_comment, _user) -> raise("CommentService was called!") end] do

      assert_error_sent :not_found, fn ->
        delete conn, "/comments/1"
      end
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not invoke the CommentService and instead redirects to the login page", %{conn: conn},
      CommentService, [], [delete!: fn(_comment, _user) -> raise("CommentService was called!") end] do

      comment = insert(:blog_post_comment)
      conn = delete conn, "/comments/#{comment.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
