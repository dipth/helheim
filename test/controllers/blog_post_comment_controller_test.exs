defmodule Helheim.BlogPostCommentControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.BlogPostCommentService

  @post_attrs %{foo: "bar"}
  @call_attrs %{"foo" => "bar"}

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user, :create_blog_post]

    test_with_mock "it redirects to the blog post with a success flash message when successfull", %{conn: conn, user: user, blog_post: blog_post},
      BlogPostCommentService, [], [insert: fn(_attrs,_author,_blog_post) -> {:ok, %{comment: %{}, notification: %{}}} end] do

      conn = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @post_attrs
      assert called BlogPostCommentService.insert(@call_attrs, user, blog_post)
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, blog_post.user.id, blog_post.id)
      assert get_flash(conn, :success) == gettext("Comment created successfully")
    end

    test_with_mock "it redirects to the blog post with an error flash message when unsuccessfull", %{conn: conn, user: user, blog_post: blog_post},
      BlogPostCommentService, [], [insert: fn(_attrs,_author,_blog_post) -> {:error, :comment, %{}, []} end] do

      conn = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @post_attrs
      assert called BlogPostCommentService.insert(@call_attrs, user, blog_post)
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, blog_post.user.id, blog_post.id)
      assert get_flash(conn, :error) == gettext("Unable to create comment")
    end

    test_with_mock "it does not invoke the BlogPostCommentService if the blog post does not exist but instead shows a 404 error", %{conn: conn},
      BlogPostCommentService, [], [insert: fn(_attrs,_author,_blog_post) -> raise("BlogPostCommentService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/blog_posts/1/comments", comment: @post_attrs
      end
    end
  end

  describe "create/2 when not signed in" do
    setup [:create_blog_post]

    test_with_mock "it does not invoke the BlogPostCommentService", %{conn: conn, blog_post: blog_post},
      BlogPostCommentService, [], [insert: fn(_attrs,_author,_blog_post) -> raise("BlogPostCommentService was called!") end] do

      post conn, "/blog_posts/#{blog_post.id}/comments", comment: @post_attrs
    end

    test "it redirects to the login page", %{conn: conn, blog_post: blog_post} do
      conn = post conn, "/blog_posts/#{blog_post.id}/comments", comment: @post_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  defp create_blog_post(_context) do
    [blog_post: insert(:blog_post)]
  end
end
