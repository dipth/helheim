defmodule Helheim.BlogPostControllerTest do
  use Helheim.ConnCase
  import Helheim.Factory
  alias Helheim.BlogPost

  @valid_attrs %{body: "Body Text", title: "Title String"}
  @invalid_attrs %{body: "   ", title: "   "}

  describe "index/2" do
    test "it returns a successful response when supplying an existing user id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      conn = get conn, "/profiles/#{user.id}/blog_posts"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an non-existing user id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/999999/blog_posts"
      end
    end

    test "it only shows blog posts from the specified user", %{conn: conn} do
      blog_post_1 = insert(:blog_post, title: "Blog Post 1")
      blog_post_2 = insert(:blog_post, title: "Blog Post 2")
      user = blog_post_1.user
      conn = conn |> sign_in(user)
      conn = get conn, "/profiles/#{user.id}/blog_posts"
      assert conn.resp_body =~ blog_post_1.title
      refute conn.resp_body =~ blog_post_2.title
    end

    test "it redirects to the login page when not signed in", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/blog_posts"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  describe "new/2" do
    test "it returns a successful response when signed in", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      conn = get conn, "/blog_posts/new"
      assert html_response(conn, 200) =~ gettext("New Blog Post")
    end

    test "it redirects to the login page when not signed in", %{conn: conn} do
      conn = get conn, "/blog_posts/new"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  describe "create/2" do
    test "it creates a new blog post and associates it with the signed in user when signed in and posting valid params", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      conn = post conn, "/blog_posts", blog_post: @valid_attrs
      blog_post = Repo.one(BlogPost)
      assert blog_post.title == @valid_attrs.title
      assert blog_post.body == @valid_attrs.body
      assert blog_post.user_id == user.id
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, user, blog_post)
    end

    test "it does not create a new blog post and re-renders the new template when posting invalid params", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      conn = post conn, "/blog_posts", blog_post: @invalid_attrs
      refute Repo.one(BlogPost)
      assert html_response(conn, 200) =~ gettext("New Blog Post")
    end

    test "it does not create a new blog post and instead redirects to the login page when not signed in", %{conn: conn} do
      conn = post conn, "/blog_posts", blog_post: @valid_attrs
      refute Repo.one(BlogPost)
      assert redirected_to(conn) == session_path(conn, :new)
    end

    test "it is impossible to fake the user_id of a blog post", %{conn: conn} do
      user_1 = insert(:user)
      user_2 = insert(:user)
      conn = conn |> sign_in(user_1)
      post conn, "/blog_posts", blog_post: Map.merge(@valid_attrs, %{user_id: user_2.id})
      blog_post = Repo.one(BlogPost)
      assert blog_post.user_id == user_1.id
    end

    test "it trims whitespace from the title", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      post conn, "/blog_posts", blog_post: Map.merge(@valid_attrs, %{title: "   Foo Bar   "})
      blog_post = Repo.one(BlogPost)
      assert blog_post.title == "Foo Bar"
    end
  end

  describe "show/2" do
    test "it returns a successful response when supplying an existing blog post id matching an existing user id", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = blog_post.user
      conn = conn |> sign_in(user)
      conn = get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/blog_posts/999999"
      end
    end

    test "it redirects to an error page when supplying a user id that does not own the blog post", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}"
      end
    end

    test "it redirects when not signed in", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = blog_post.user
      conn = get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}"
      assert html_response(conn, 302)
    end
  end

  describe "edit/2" do
    test "it returns a successful response when signed in and supplying an existing blog post id", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = blog_post.user
      conn = conn |> sign_in(user)
      conn = get conn, "/blog_posts/#{blog_post.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Blog Post")
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        get conn, "/blog_posts/999999/edit"
      end
    end

    test "it redirects to an error page when supplying a blog post id belonging to another user", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        get conn, "/blog_posts/#{blog_post.id}/edit"
      end
    end

    test "it redirects to the login page when not signed in", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = get conn, "/blog_posts/#{blog_post.id}/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  describe "update/2" do
    test "it updates the blog post when signed in and posting valid params and existing blog post id", %{conn: conn} do
      blog_post = insert(:blog_post, title: "Foo", body: "Bar")
      user = blog_post.user
      conn = conn |> sign_in(user)
      conn = put conn, "/blog_posts/#{blog_post.id}", blog_post: @valid_attrs
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == @valid_attrs.title
      assert blog_post.body == @valid_attrs.body
      assert blog_post.user_id == user.id
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, user, blog_post)
    end

    test "it does not update the blog post and re-renders the edit template when posting invalid params", %{conn: conn} do
      blog_post = insert(:blog_post, title: "Foo", body: "Bar")
      user = blog_post.user
      conn = conn |> sign_in(user)
      conn = put conn, "/blog_posts/#{blog_post.id}", blog_post: @invalid_attrs
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Foo"
      assert blog_post.body == "Bar"
      assert html_response(conn, 200) =~ gettext("Edit Blog Post")
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        put conn, "/blog_posts/999999", blog_post: @valid_attrs
      end
    end

    test "it does not update the blog post and redirects to an error page when supplying a blog post id belonging to another user", %{conn: conn} do
      blog_post = insert(:blog_post, title: "Foo", body: "Bar")
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        put conn, "/blog_posts/#{blog_post.id}", blog_post: @valid_attrs
      end
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Foo"
      assert blog_post.body == "Bar"
    end

    test "it does not update the blog post and instead redirects to the login page when not signed in", %{conn: conn} do
      blog_post = insert(:blog_post, title: "Foo", body: "Bar")
      conn = put conn, "/blog_posts/#{blog_post.id}", blog_post: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Foo"
      assert blog_post.body == "Bar"
    end

    test "it is impossible to fake the user_id of a blog post", %{conn: conn} do
      blog_post = insert(:blog_post)
      user_1 = blog_post.user
      user_2 = insert(:user)
      conn = conn |> sign_in(user_1)
      put conn, "/blog_posts/#{blog_post.id}", blog_post: Map.merge(@valid_attrs, %{user_id: user_2.id})
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.user_id == user_1.id
    end

    test "it trims whitespace from the title", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = blog_post.user
      conn = conn |> sign_in(user)
      put conn, "/blog_posts/#{blog_post.id}", blog_post: Map.merge(@valid_attrs, %{title: "   Trim Me   "})
      blog_post = Repo.get(BlogPost, blog_post.id)
      assert blog_post.title == "Trim Me"
    end
  end

  describe "delete/2" do
    test "it deletes the blog post when signed in and posting existing blog post id belonging to the user", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = blog_post.user
      conn = conn |> sign_in(user)
      conn = delete conn, "/blog_posts/#{blog_post.id}"
      refute Repo.get(BlogPost, blog_post.id)
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :index, user)
    end

    test "it redirects to an error page when supplying a non-existant blog post id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        delete conn, "/blog_posts/999999"
      end
    end

    test "it does not delete the blog post and redirects to an error page when supplying a blog post id belonging to another user", %{conn: conn} do
      blog_post = insert(:blog_post)
      user = insert(:user)
      conn = conn |> sign_in(user)
      assert_error_sent :not_found, fn ->
        delete conn, "/blog_posts/#{blog_post.id}"
      end
      assert Repo.get(BlogPost, blog_post.id)
    end

    test "it does not delete the blog post and instead redirects to the login page when not signed in", %{conn: conn} do
      blog_post = insert(:blog_post)
      conn = delete conn, "/blog_posts/#{blog_post.id}"
      assert redirected_to(conn) == session_path(conn, :new)
      assert Repo.get(BlogPost, blog_post.id)
    end
  end
end
