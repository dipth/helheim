defmodule HelheimWeb.ProfileControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  use Bamboo.Test
  alias Helheim.Repo
  alias Helheim.User

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/profiles"
      assert html_response(conn, 200)
    end

    test "it shows all users", %{conn: conn} do
      user_1 = insert(:user, username: "Username 1")
      user_2 = insert(:user, username: "Username 2")
      conn = get conn, "/profiles"
      assert conn.resp_body =~ user_1.username
      assert conn.resp_body =~ user_2.username
    end

    test "does not show users who are not confirmed", %{conn: conn} do
      user = insert(:user, confirmed_at: nil)
      conn = get conn, "/profiles"
      refute conn.resp_body =~ user.username
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/profiles"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

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

    test_with_mock "it tracks the view", %{conn: conn, user: user},
      Helheim.VisitorLogEntry, [:passthrough], [track!: fn(_user, _subject) -> {:ok} end] do

      profile = Repo.get(User, insert(:user).id)
      get conn, "/profiles/#{profile.id}"
      assert called Helheim.VisitorLogEntry.track!(user, profile)
    end

    test "redirects to the block page if the specified profile blocks the current user", %{conn: conn, user: user} do
      profile = insert(:user)
      insert(:block, blocker: profile, blockee: user)
      conn = get conn, "/profiles/#{profile.id}"
      assert redirected_to(conn) == public_profile_block_path(conn, :show, profile)
    end

    test "does not show deleted comments", %{conn: conn} do
      comment = insert(:profile_comment, deleted_at: DateTime.utc_now, body: "This is a deleted comment")
      profile = comment.profile
      conn    = get conn, "/profiles/#{profile.id}"
      refute html_response(conn, 200) =~ "This is a deleted comment"
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the login page when specifying an id", %{conn: conn} do
      conn = get conn, "/profile"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end

    test "it redirects to the login page when specifying an existing id", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
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
      assert redirected_to(conn) =~ session_path(conn, :new)
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

    # TODO: Figure out a better way to test file size limits
    # test "it does not allow to upload of profile images larger than 3 MB", %{conn: conn, user: user} do
    #   upload = %Plug.Upload{path: "test/files/3.1MB.jpg", filename: "3.1MB.jpg"}
    #   conn = put conn, "/profile", user: %{avatar: upload}
    #   assert html_response(conn, 200) =~ gettext("Profile Settings")
    #   user = Repo.get(User, user.id)
    #   refute user.avatar
    # end

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
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
