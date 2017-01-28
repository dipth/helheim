defmodule Helheim.BlogPostCommentServiceTest do
  use Helheim.ModelCase
  import Helheim.Router.Helpers
  alias Helheim.BlogPostCommentService
  alias Helheim.Comment
  alias Helheim.Notification

  @valid_attrs %{ body: "Foo Bar" }
  @invalid_attrs %{ body: "   " }

  describe "insert/3 with valid attrs, author and blog post" do
    setup [:create_author_and_blog_post]

    test "creates a comment on the blog post from the author with the attrs", %{author: author, blog_post: blog_post} do
      BlogPostCommentService.insert(@valid_attrs, author, blog_post)
      comment = Repo.get_by(Comment, @valid_attrs)
      assert comment.author_id == author.id
      assert comment.blog_post_id == blog_post.id
    end

    test "creates a notification for the user of the blog post", %{author: author, blog_post: blog_post} do
      BlogPostCommentService.insert(@valid_attrs, author, blog_post)
      notification = Repo.one(Notification)
      assert notification.user_id == blog_post.user.id
      assert notification.title == gettext("%{username} wrote a comment on your blog post: %{title}", username: author.username, title: blog_post.title)
      assert notification.path == public_profile_blog_post_path(Helheim.Endpoint, :show, blog_post.user.id, blog_post.id)
    end

    test "does not create a notification if the author is the same as the user of the blog post", %{blog_post: blog_post} do
      BlogPostCommentService.insert(@valid_attrs, blog_post.user, blog_post)
      refute Repo.one(Notification)
    end

    test "returns :ok and a Map including a comment and a notification", %{author: author, blog_post: blog_post} do
      {:ok, %{comment: comment, notification: notification}} = BlogPostCommentService.insert(@valid_attrs, author, blog_post)
      assert comment
      assert notification
    end

    test "it does not allow spoofing the author", %{author: author, blog_post: blog_post} do
      BlogPostCommentService.insert(Map.merge(@valid_attrs, %{author_id: blog_post.user.id}), author, blog_post)
      comment = Repo.one(Comment)
      assert comment.author_id == author.id
    end

    test "it trims whitespace from the body", %{author: author, blog_post: blog_post} do
      BlogPostCommentService.insert(Map.merge(@valid_attrs, %{body: "   Foo   "}), author, blog_post)
      comment = Repo.one(Comment)
      assert comment.body == "Foo"
    end
  end

  describe "insert/3 with invalid attrs" do
    setup [:create_author_and_blog_post]

    test "does not create any comments", %{author: author, blog_post: blog_post} do
      BlogPostCommentService.insert(@invalid_attrs, author, blog_post)
      refute Repo.one(Comment)
    end

    test "does not create any notifications", %{author: author, blog_post: blog_post} do
      BlogPostCommentService.insert(@invalid_attrs, author, blog_post)
      refute Repo.one(Notification)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{author: author, blog_post: blog_post} do
      {:error, failed_operation, failed_value, changes_so_far} = BlogPostCommentService.insert(@invalid_attrs, author, blog_post)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end
  end

  defp create_author_and_blog_post(_context) do
    author    = insert(:user)
    blog_post = insert(:blog_post)
    [author: author, blog_post: blog_post]
  end
end
