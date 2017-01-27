defmodule Helheim.BlogPostCommentControllerTest do
  use Helheim.ConnCase
  alias Helheim.Comment

  @valid_attrs %{body: "Body Text"}
  @invalid_attrs %{body: ""}

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new comment for the blog post with the currently signed in user as the author and redirects back to the blog post", context = %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @valid_attrs
      comment = Repo.one(Comment)
      assert comment.author_id == context[:user].id
      assert comment.blog_post_id == blog_post.id
      assert comment.body == @valid_attrs.body
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, blog_post.user.id, blog_post.id)
    end

    test "it does not create any comments when posting invalid attributes", %{conn: conn} do
      blog_post = insert(:blog_post)
      post conn, "/blog_posts/#{blog_post.id}/comments", comment: @invalid_attrs
      refute Repo.one(Comment)
    end

    test "it does not create any comments if the blog_post does not exist but instead shows a 404 error", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        post conn, "/blog_posts/1/comments", comment: @valid_attrs
      end
      refute Repo.one(Comment)
    end

    test "it does not allow spoofing the author", context = %{conn: conn} do
      blog_post = insert(:blog_post)
      post conn, "/blog_posts/#{blog_post.id}/comments", comment: Map.merge(@valid_attrs, %{author_id: blog_post.user.id})
      comment = Repo.one(Comment)
      assert comment.author_id == context[:user].id
    end

    test "it trims whitespace from the body", %{conn: conn} do
      blog_post = insert(:blog_post)
      post conn, "/blog_posts/#{blog_post.id}/comments", comment: Map.merge(@valid_attrs, %{body: "   Foo   "})
      comment = Repo.one(Comment)
      assert comment.body == "Foo"
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create any comments", %{conn: conn} do
      blog_post = insert(:blog_post)
      post conn, "/blog_posts/#{blog_post.id}/comments", comment: @valid_attrs
      refute Repo.one(Comment)
    end

    test "it redirects to the login page", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
