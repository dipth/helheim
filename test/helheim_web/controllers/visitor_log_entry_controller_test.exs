defmodule HelheimWeb.VisitorLogEntryControllerTest do
  use HelheimWeb.ConnCase

  ##############################################################################
  # index/2 for a profile
  describe "index/2 for a profile when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying a valid profile_id", %{conn: conn, user: user} do
      conn = get conn, "/profiles/#{user.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, user: user} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id + 1}/visitor_log_entries"
      end
    end

    test "it redirects back to the profile page if the logged in user is not the same as the profile", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/visitor_log_entries"
      assert redirected_to(conn) == public_profile_path(conn, :show, user)
    end

    test "it supports showing log entries where the user is deleted", %{conn: conn, user: user} do
      insert(:visitor_log_entry, profile: user, user: nil)
      conn = get conn, "/profiles/#{user.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end
  end

  describe "index/2 for a profile when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when supplying a valid profile_id", %{conn: conn, admin: admin} do
      conn = get conn, "/profiles/#{admin.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, admin: admin} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id + 1}/visitor_log_entries"
      end
    end

    test "it returns a successful response if the logged in user is not the same as the profile", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end
  end

  describe "index/2 for a profile when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}/visitor_log_entries"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # index/2 for a blog post
  describe "index/2 for a blog post when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying a valid profile_id and blog_post_id", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      conn      = get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id + 1}/blog_posts/#{blog_post.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid blog_post_id", %{conn: conn, user: user} do
      blog_post = insert(:blog_post, user: user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id + 1}/visitor_log_entries"
      end
    end

    test "it redirects back to the blog post if the logged in user is not the same as the owner of the blog post", %{conn: conn} do
      user      = insert(:user)
      blog_post = insert(:blog_post, user: user)
      conn      = get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}/visitor_log_entries"
      assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, user, blog_post)
    end
  end

  describe "index/2 for a blog post when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when supplying a valid profile_id and blog_post_id", %{conn: conn, admin: admin} do
      blog_post = insert(:blog_post, user: admin)
      conn      = get conn, "/profiles/#{admin.id}/blog_posts/#{blog_post.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, admin: admin} do
      blog_post = insert(:blog_post, user: admin)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id + 1}/blog_posts/#{blog_post.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid blog_post_id", %{conn: conn, admin: admin} do
      blog_post = insert(:blog_post, user: admin)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id}/blog_posts/#{blog_post.id + 1}/visitor_log_entries"
      end
    end

    test "it returns a successful response if the logged in user is not the same as the owner of the blog post", %{conn: conn} do
      user      = insert(:user)
      blog_post = insert(:blog_post, user: user)
      conn      = get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end
  end

  describe "index/2 for a blog post when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user      = insert(:user)
      blog_post = insert(:blog_post, user: user)
      conn      = get conn, "/profiles/#{user.id}/blog_posts/#{blog_post.id}/visitor_log_entries"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # index/2 for a photo album
  describe "index/2 for a photo album when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying a valid profile_id and photo_album_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id + 1}/photo_albums/#{photo_album.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid photo_album_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id + 1}/visitor_log_entries"
      end
    end

    test "it redirects back to the photo album if the logged in user is not the same as the owner of the photo album", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/visitor_log_entries"
      assert redirected_to(conn) == public_profile_photo_album_path(conn, :show, user, photo_album)
    end
  end

  describe "index/2 for a photo album when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when supplying a valid profile_id and photo_album_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      conn        = get conn, "/profiles/#{admin.id}/photo_albums/#{photo_album.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id + 1}/photo_albums/#{photo_album.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid photo_album_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id}/photo_albums/#{photo_album.id + 1}/visitor_log_entries"
      end
    end

    test "it returns a successful response if the logged in user is not the same as the owner of the photo album", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end
  end

  describe "index/2 for a photo album when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/visitor_log_entries"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # index/2 for a photo
  describe "index/2 for a photo when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when supplying a valid profile_id, photo_album_id and photo_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id + 1}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid photo_album_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id + 1}/photos/#{photo.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid photo_id", %{conn: conn, user: user} do
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id + 1}/visitor_log_entries"
      end
    end

    test "it redirects back to the photo if the logged in user is not the same as the owner of the photo", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      assert redirected_to(conn) == public_profile_photo_album_photo_path(conn, :show, user, photo_album, photo)
    end
  end

  describe "index/2 for a photo when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when supplying a valid profile_id, photo_album_id and photo_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      photo       = insert(:photo, photo_album: photo_album)
      conn        = get conn, "/profiles/#{admin.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an invalid profile_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      photo       = insert(:photo, photo_album: photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id + 1}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid photo_album_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      photo       = insert(:photo, photo_album: photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id}/photo_albums/#{photo_album.id + 1}/photos/#{photo.id}/visitor_log_entries"
      end
    end

    test "it redirects to an error page when supplying an invalid photo_id", %{conn: conn, admin: admin} do
      photo_album = insert(:photo_album, user: admin)
      photo       = insert(:photo, photo_album: photo_album)
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/#{admin.id}/photo_albums/#{photo_album.id}/photos/#{photo.id + 1}/visitor_log_entries"
      end
    end

    test "it returns a successful response if the logged in user is not the same as the owner of the photo", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      assert html_response(conn, 200)
    end
  end

  describe "index/2 for a photo when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      user        = insert(:user)
      photo_album = insert(:photo_album, user: user)
      photo       = insert(:photo, photo_album: photo_album)
      conn        = get conn, "/profiles/#{user.id}/photo_albums/#{photo_album.id}/photos/#{photo.id}/visitor_log_entries"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
