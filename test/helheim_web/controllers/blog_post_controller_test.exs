defmodule HelheimWeb.BlogPostControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.BlogPost
  alias Helheim.NotificationSubscription
  alias Helheim.User

  @valid_attrs %{body: "Body Text", title: "Title String", visibility: "public"}
  @invalid_attrs %{body: "   ", title: "   ", visibility: ""}

  ##############################################################################
  # index/2 for a single user
  describe "index/2 for a single user when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an existing user id", %{conn: conn, user: user} do
      conn = get conn, "/profiles/#{user.id}/blog_posts"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an non-existing user id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/999999/blog_posts"
      end
    end

    test "it only shows blog posts from the specified user", %{conn: conn} do
      blog_post_1 = insert(:blog_post, title: "Blog Post 1")
      blog_post_2 = insert(:blog_post, title: "Blog Post 2")
      conn = get conn, "/profiles/#{blog_post_1.user.id}/blog_posts"
      assert conn.resp_body =~ blog_post_1.title
      refute conn.resp_body =~ blog_post_2.title
    end

    test "it does not show unpublished blog posts when browsed by another user", %{conn: conn} do
      blog_post = insert(:blog_post, published: false)
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "it does show unpublished blog posts when browsed by the same user", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, published: false)
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "it redirects to a block page when the specified profile is blocking the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      conn  = get conn, "/profiles/#{block.blocker.id}/blog_posts"
      assert redirected_to(conn) == block_path(conn, :show, block.blocker)
    end

    test "does not show blog posts that are set to private and the current user is not the author of the blog post", %{conn: conn} do
      blog_post = insert(:blog_post, visibility: "private", title: "My private blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to private and the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "private", title: "My private blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to verified_only when the current user is not verified", %{conn: conn, user: user} do
      refute user.verified_at
      blog_post = insert(:blog_post, visibility: "verified_only", title: "My verified_only blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to verified_only and the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "verified_only", title: "My verified_only blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to verified_only and the current user is verified", %{conn: conn} do
      # {:ok, _user} = Ecto.Changeset.change(user, verified_at: Timex.now) |> Repo.update
      user = insert(:user, verified_at: Timex.now)
      blog_post = insert(:blog_post, visibility: "verified_only", title: "My verified_only blog post")
      conn = conn
             |> sign_in(user)
             |> get("/profiles/#{blog_post.user.id}/blog_posts")
      assert conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to friends_only and the current user is not friends with the author of the blog post", %{conn: conn} do
      blog_post = insert(:blog_post, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to friends_only and the current user is friends with the author of the blog post", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship, sender: user, recipient: author)
      blog_post = insert(:blog_post, user: author, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to friends_only and the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to friends_only and the current user is only pending friends with the author of the blog post", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship_request, sender: user, recipient: author)
      blog_post = insert(:blog_post, user: author, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end
  end

  describe "index/2 for a single user when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/blog_posts"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # index/2 for all users
  describe "index/2 for all users when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/blog_posts"
      assert html_response(conn, 200)
    end

    test "it shows blog posts from all users", %{conn: conn} do
      blog_post_1 = insert(:blog_post, title: "Blog Post 1")
      blog_post_2 = insert(:blog_post, title: "Blog Post 2")
      conn = get conn, "/blog_posts"
      assert conn.resp_body =~ blog_post_1.title
      assert conn.resp_body =~ blog_post_2.title
    end

    test "it does not show unpublished blog posts", %{conn: conn} do
      blog_post = insert(:blog_post, published: false)
      conn = get conn, "/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to private even when the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "private", title: "My private blog post")
      conn = get conn, "/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to verified_only when the current user is not verified", %{conn: conn, user: user} do
      refute user.verified_at
      blog_post = insert(:blog_post, visibility: "verified_only", title: "My verified_only blog post")
      conn = get conn, "/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to verified_only when the current user is the author of the blog post", %{conn: conn, user: user} do
      refute user.verified_at
      blog_post = insert(:blog_post, user: user, visibility: "verified_only", title: "My verified_only blog post")
      conn = get conn, "/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to verified_only when the current user is verified", %{conn: conn} do
      user = insert(:user, verified_at: Timex.now)
      blog_post = insert(:blog_post, user: user, visibility: "verified_only", title: "My verified_only blog post")
      conn = conn
             |> sign_in(user)
             |> get("/blog_posts")
      assert conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to friends_only and the current user is not friends with the author of the blog post", %{conn: conn} do
      blog_post = insert(:blog_post, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "shows blog posts that are set to friends_only and the current user is friends with the author of the blog post", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship, sender: user, recipient: author)
      blog_post = insert(:blog_post, user: author, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "shows blog post that are set to friends_only and the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts that are set to friends_only and the current user is only pending friends with the author of the blog post", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship_request, sender: user, recipient: author)
      blog_post = insert(:blog_post, user: author, visibility: "friends_only", title: "My friends_only blog post")
      conn = get conn, "/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "does not show blog posts from users that are ignored by the current user", %{conn: conn, user: user} do
      other_user = insert(:user)
      blog_post = insert(:blog_post, user: other_user)
      insert(:ignore, ignorer: user, ignoree: other_user)
      conn = get conn, "/blog_posts"
      refute conn.resp_body =~ blog_post.title
    end

    test "shows blog posts from users that are ignoring the current user", %{conn: conn, user: user} do
      other_user = insert(:user)
      blog_post = insert(:blog_post, user: other_user)
      insert(:ignore, ignorer: other_user, ignoree: user)
      conn = get conn, "/blog_posts"
      assert conn.resp_body =~ blog_post.title
    end
  end

  describe "index/2 for all users when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/blog_posts"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/blog_posts/new"
      assert html_response(conn, 200) =~ gettext("New Blog Post")
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/blog_posts/new"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new blog post and associates it with the signed in user when posting valid params", %{conn: conn, user: user} do
      conn = post conn, "/blog_posts", blog_post: @valid_attrs
      blog_post = Repo.one(BlogPost)
      assert blog_post.title == @valid_attrs.title
      assert blog_post.body == @valid_attrs.body
      assert blog_post.user_id == user.id
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, user, blog_post)
    end

    test "it creates a notification subscription for the newly created blog post when posting valid params", %{conn: conn} do
      post conn, "/blog_posts", blog_post: @valid_attrs
      blog_post = Repo.one(BlogPost)
      sub = Repo.one(NotificationSubscription)
      assert sub.user_id == blog_post.user_id
      assert sub.type == "comment"
      assert sub.blog_post_id == blog_post.id
      assert sub.enabled == true
    end

    test "it does not create a new blog post and re-renders the new template when posting invalid params", %{conn: conn} do
      conn = post conn, "/blog_posts", blog_post: @invalid_attrs
      refute Repo.one(BlogPost)
      assert html_response(conn, 200) =~ gettext("New Blog Post")
    end

    test "it is impossible to fake the user_id of a blog post", %{conn: conn, user: user} do
      other_user = insert(:user)
      post conn, "/blog_posts", blog_post: Map.merge(@valid_attrs, %{user_id: other_user.id})
      blog_post = Repo.one(BlogPost)
      assert blog_post.user_id == user.id
    end

    test "it trims whitespace from the title", %{conn: conn} do
      post conn, "/blog_posts", blog_post: Map.merge(@valid_attrs, %{title: "   Foo Bar   "})
      blog_post = Repo.one(BlogPost)
      assert blog_post.title == "Foo Bar"
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a new blog post and instead redirects to the login page", %{conn: conn} do
      conn = post conn, "/blog_posts", blog_post: @valid_attrs
      refute Repo.one(BlogPost)
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an existing blog post id matching an existing user id", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn, user: user} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/blog_posts/1"
      end
    end

    test "it redirects to an error page when supplying a user id that does not own the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}"
      end
    end

    test "it supports showing comments from deleted users", %{conn: conn} do
      comment   = insert(:blog_post_comment, author: nil)
      blog_post = comment.blog_post
      conn      = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test_with_mock "it tracks the view", %{conn: conn, user: user},
      Helheim.VisitorLogEntry, [:passthrough], [track!: fn(_user, _subject) -> {:ok} end] do

      blog_post = insert(:blog_post)
      get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert_called_with_pattern Helheim.VisitorLogEntry, :track!, fn(args) ->
        user_id      = user.id
        blog_post_id = blog_post.id
        [%User{id: ^user_id}, %BlogPost{id: ^blog_post_id}] = args
      end
    end

    test "redirects to an error page when the blog post is not published or owned by the current user", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, published: false)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}"
      end
    end

    test "returns a successful response when the blog post is not published but owned by the current user", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, published: false, user: user)
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to a block page when the specified profile is blocking the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      blog_post = insert(:blog_post, user: block.blocker)
      conn  = get conn, "/profiles/#{block.blocker.id}/blog_posts/#{blog_post.id}"
      assert redirected_to(conn) == block_path(conn, :show, block.blocker)
    end

    test "does not show deleted comments", %{conn: conn} do
      comment   = insert(:blog_post_comment, deleted_at: DateTime.utc_now, body: "This is a deleted comment")
      blog_post = comment.blog_post
      conn      = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      refute html_response(conn, 200) =~ "This is a deleted comment"
    end

    test "does not show comments if comments are disabled for the blog post", %{conn: conn} do
      blog_post = insert(:blog_post, hide_comments: true)
      _comment  = insert(:blog_post_comment, body: "This is a comment")
      conn      = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      refute html_response(conn, 200) =~ "This is a comment"
      assert html_response(conn, 200) =~ gettext("Comments have been disabled for this blog post")
    end

    test "redirects to an error page when the blog post is set to private and the current user is not the author of the blog post", %{conn: conn} do
      blog_post = insert(:blog_post, visibility: "private")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      end
    end

    test "successfully shows a blog post that is set to private when the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "private")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "redirects to an error page when the blog post is set to verified_only and the current user is not verified or the author of the blog post", %{conn: conn, user: user} do
      refute user.verified_at
      blog_post = insert(:blog_post, visibility: "verified_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      end
    end

    test "successfully shows a blog post that is set to verified_only when the current user is the author of the blog post", %{conn: conn, user: user} do
      refute user.verified_at
      blog_post = insert(:blog_post, user: user, visibility: "verified_only")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "successfully shows a blog post that is set to verified_only when the current user is verified", %{conn: conn} do
      user = insert(:user, verified_at: Timex.now)
      blog_post = insert(:blog_post, user: user, visibility: "verified_only")
      conn = conn
             |> sign_in(user)
             |> get("/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}")
      assert html_response(conn, 200)
    end

    test "redirects to an error page when the blog post is set to friends_only and the current user is not friends with the author of the blog post", %{conn: conn} do
      blog_post = insert(:blog_post, visibility: "friends_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      end
    end

    test "successfully shows a blog post that is set to friends_only when the current user is the author of the blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, visibility: "friends_only")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "successfully shows a blog post that is set to private when the current user is friends with the author of the blog post", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship, sender: user, recipient: author)
      blog_post = insert(:blog_post, user: author, visibility: "friends_only")
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "redirects to an error page when the blog post is set to friends_only and the current user is only pending friends with the author of the blog post", %{conn: conn, user: user} do
      author = insert(:user)
      insert(:friendship_request, sender: user, recipient: author)
      blog_post = insert(:blog_post, user: author, visibility: "friends_only")
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = get conn, "/profiles/#{blog_post.user.id}/blog_posts/#{blog_post.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying an existing blog post id", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      conn = get conn, "/blog_posts/#{blog_post.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Blog Post")
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/blog_posts/1/edit"
      end
    end

    test "it redirects to an error page when supplying a blog post id belonging to another user", %{conn: conn} do
      blog_post = insert(:blog_post)
      assert_error_sent :not_found, fn ->
        get conn, "/blog_posts/#{blog_post.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = get conn, "/blog_posts/#{blog_post.id}/edit"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it updates the blog post when posting valid params and existing blog post id", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, title: "Foo", body: "Bar")
      conn = put conn, "/blog_posts/#{blog_post.id}", blog_post: @valid_attrs
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == @valid_attrs.title
      assert blog_post.body == @valid_attrs.body
      assert blog_post.user_id == user.id
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, user, blog_post)
    end

    test "it does not update the blog post and re-renders the edit template when posting invalid params", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user, title: "Foo", body: "Bar")
      conn = put conn, "/blog_posts/#{blog_post.id}", blog_post: @invalid_attrs
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Foo"
      assert blog_post.body == "Bar"
      assert html_response(conn, 200) =~ gettext("Edit Blog Post")
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        put conn, "/blog_posts/1", blog_post: @valid_attrs
      end
    end

    test "it does not update the blog post and redirects to an error page when supplying a blog post id belonging to another user", %{conn: conn} do
      blog_post = insert(:blog_post, title: "Foo", body: "Bar")
      assert_error_sent :not_found, fn ->
        put conn, "/blog_posts/#{blog_post.id}", blog_post: @valid_attrs
      end
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Foo"
      assert blog_post.body == "Bar"
    end

    test "it is impossible to fake the user_id of a blog post", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      other_user = insert(:user)
      put conn, "/blog_posts/#{blog_post.id}", blog_post: Map.merge(@valid_attrs, %{user_id: other_user.id})
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.user_id == user.id
    end

    test "it trims whitespace from the title", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      put conn, "/blog_posts/#{blog_post.id}", blog_post: Map.merge(@valid_attrs, %{title: "   Trim Me   "})
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Trim Me"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the blog post and instead redirects to the sign in page", %{conn: conn} do
      blog_post = insert(:blog_post, title: "Foo", body: "Bar")
      conn = put conn, "/blog_posts/#{blog_post.id}", blog_post: @valid_attrs
      assert redirected_to(conn) =~ session_path(conn, :new)
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Foo"
      assert blog_post.body == "Bar"
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it deletes the blog post when posting existing blog post id belonging to the user", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      conn = delete conn, "/blog_posts/#{blog_post.id}"
      refute Repo.get(BlogPost, blog_post.id)
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :index, user)
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        delete conn, "/blog_posts/1"
      end
    end

    test "it does not delete the blog post and redirects to an error page when supplying a blog post id belonging to another user", %{conn: conn} do
      blog_post = insert(:blog_post)
      assert_error_sent :not_found, fn ->
        delete conn, "/blog_posts/#{blog_post.id}"
      end
      assert Repo.get(BlogPost, blog_post.id)
    end
  end

  describe "delete/2 when not signed in" do
    test "it does not delete the blog post and instead redirects to the sign in page", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = delete conn, "/blog_posts/#{blog_post.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert Repo.get(BlogPost, blog_post.id)
    end
  end
end
