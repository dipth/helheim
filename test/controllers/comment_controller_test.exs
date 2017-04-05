defmodule Helheim.CommentControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.CommentService
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.BlogPost

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
end
