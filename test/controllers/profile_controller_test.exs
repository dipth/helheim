defmodule Helheim.ProfileControllerTest do
  use Helheim.ConnCase
  use Bamboo.Test
  alias Helheim.Repo
  alias Helheim.User
  import Helheim.Factory

  describe "show/2" do
    test "it returns a successful response when signed in and not specifying an id", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/profile"
      assert html_response(conn, 200)
    end

    test "it returns a successful response when signed in and specifying an existing id", %{conn: conn} do
      user = insert(:user)
      conn = conn |> sign_in(user)
      conn = get conn, "/profiles/#{user.id}"
      assert html_response(conn, 200)
    end

    test "it redirects when signed in and specifying a non-existing id", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/profiles/999999999"
      assert html_response(conn, 302)
    end

    test "it redirects when not signed in and not specifying an id", %{conn: conn} do
      conn = get conn, "/profile"
      assert html_response(conn, 302)
    end

    test "it redirects when not signed in and specifying an existing id", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/profiles/#{user.id}"
      assert html_response(conn, 302)
    end
  end

  describe "new/2" do
    test "it returns a successful response when signed in", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/profile/edit"
      assert html_response(conn, 200) =~ gettext("Profile Settings")
    end

    test "it redirects when not signed in", %{conn: conn} do
      conn = get conn, "/profile/edit"
      assert html_response(conn, 302)
    end
  end

  describe "create/2" do
    test "it allows the update of the users profile photo", %{conn: conn} do
      user = insert(:user, profile_text: "Foo")
      upload = %Plug.Upload{path: "test/files/1.0MB.jpg", filename: "1.0MB.jpg"}
      conn = conn
      |> sign_in(user)
      |> post("/profile", user: %{avatar: upload}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert %{file_name: "1.0MB.jpg"} = user.avatar
    end

    test "it does not allow to upload of profile images larger than 1 MB", %{conn: conn} do
      user = insert(:user, profile_text: "Foo")
      upload = %Plug.Upload{path: "test/files/2.0MB.jpg", filename: "2.0MB.jpg"}
      conn = conn
      |> sign_in(user)
      |> post("/profile", user: %{avatar: upload}, _method: "put")
      assert html_response(conn, 200) =~ gettext("Profile Settings")
      user = Repo.get(User, user.id)
      refute user.avatar
    end

    test "it allows the update of the users profile text", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> sign_in(user)
      |> post("/profile", user: %{profile_text: "Lorem Ipsum"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.profile_text == "Lorem Ipsum"
    end

    test "it requires that the user is signed in", %{conn: conn} do
      user = insert(:user)
      conn = conn
      |> post("/profile", user: %{profile_text: "Lorem Ipsum"}, _method: "put")
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      refute user.profile_text == "Lorem Ipsum"
    end
  end
end
