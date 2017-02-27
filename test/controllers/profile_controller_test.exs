defmodule Helheim.ProfileControllerTest do
  use Helheim.ConnCase
  use Bamboo.Test
  alias Helheim.Repo
  alias Helheim.User

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when not specifying an id", %{conn: conn} do
      conn = get conn, "/profile"
      assert html_response(conn, 200)
    end

    test "it returns a successful response when specifying an existing id", %{conn: conn} do
      profile = insert(:user)
      conn = get conn, "/profiles/#{profile.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when specifying a non-existing id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/1"
      end
    end

    test "it supports showing comments from deleted users", %{conn: conn} do
      comment = insert(:profile_comment, author: nil)
      profile = comment.profile
      conn    = get conn, "/profiles/#{profile.id}"
      assert html_response(conn, 200)
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the login page when specifying an id", %{conn: conn} do
      conn = get conn, "/profile"
      assert redirected_to(conn) == session_path(conn, :new)
    end

    test "it redirects to the login page when specifying an existing id", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/profile/edit"
      assert html_response(conn, 200) =~ gettext("Profile Settings")
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/profile/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it allows the update of the users profile photo", %{conn: conn, user: user} do
      upload = %Plug.Upload{path: "test/files/1.0MB.jpg", filename: "1.0MB.jpg"}
      conn = put conn, "/profile", user: %{avatar: upload}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert %{file_name: "1.0MB.jpg"} = user.avatar
    end

    test "it does not allow to upload of profile images larger than 1 MB", %{conn: conn, user: user} do
      upload = %Plug.Upload{path: "test/files/2.0MB.jpg", filename: "2.0MB.jpg"}
      conn = put conn, "/profile", user: %{avatar: upload}
      assert html_response(conn, 200) =~ gettext("Profile Settings")
      user = Repo.get(User, user.id)
      refute user.avatar
    end

    test "it allows the update of the users profile text", %{conn: conn, user: user} do
      conn = put conn, "/profile", user: %{profile_text: "Lorem Ipsum"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.profile_text == "Lorem Ipsum"
    end
  end

  describe "update/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = put conn, "/profile", user: %{profile_text: "Lorem Ipsum"}
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
