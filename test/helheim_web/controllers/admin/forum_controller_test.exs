defmodule HelheimWeb.Admin.ForumControllerTest do
  use HelheimWeb.ConnCase
  alias Helheim.Repo
  alias Helheim.Forum

  @valid_attrs %{title: "Foo", description: "Bar"}
  @invalid_attrs %{title: "", description: ""}

  ##############################################################################
  # new/2
  describe "new/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = get conn, "/admin/forum_categories/#{forum_category.id}/forums/new"
      assert html_response(conn, 200) =~ gettext("New Forum")
    end

    test "it shows a 404 error when providing an invalid forum_category_id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/admin/forum_categories/1/forums/new"
      end
    end
  end

  describe "new/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent 403, fn ->
        get conn, "/admin/forum_categories/#{forum_category.id}/forums/new"
      end
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = get conn, "/admin/forum_categories/#{forum_category.id}/forums/new"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it creates a forum and redirects to the list of forum categories", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = post conn, "/admin/forum_categories/#{forum_category.id}/forums", forum: @valid_attrs
      forum          = Repo.one(Forum)
      assert redirected_to(conn)     == admin_forum_category_path(conn, :index)
      assert forum.forum_category_id == forum_category.id
      assert forum.title             == @valid_attrs.title
      assert forum.description       == @valid_attrs.description
    end

    test "it does not create a forum but re-renders the new template when posting invalid attributes", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = post conn, "/admin/forum_categories/#{forum_category.id}/forums", forum: @invalid_attrs
      refute Repo.one(Forum)
      assert html_response(conn, 200) =~ gettext("New Forum")
    end

    test "it shows a 404 error when providing an invalid forum_category_id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        post conn, "/admin/forum_categories/1/forums", forum: @invalid_attrs
      end
    end
  end

  describe "create/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not create a forum but shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent 403, fn ->
        post conn, "/admin/forum_categories/#{forum_category.id}/forums", forum_category: @valid_attrs
      end
      refute Repo.one(Forum)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a forum but redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = post conn, "/admin/forum_categories/#{forum_category.id}/forums", forum_category: @valid_attrs
      assert redirected_to(conn) =~ session_path(conn, :new)
      refute Repo.one(Forum)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when providing a valid id", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category)
      conn           = get conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Forum")
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent :not_found, fn ->
        get conn, "/admin/forum_categories/#{forum_category.id}/forums/1/edit"
      end
    end

    test "it shows a 404 error when providing an invalid forum_category_id", %{conn: conn} do
      forum = insert(:forum)
      assert_error_sent :not_found, fn ->
        get conn, "/admin/forum_categories/1/forums/#{forum.id}/edit"
      end
    end
  end

  describe "edit/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category)
      assert_error_sent 403, fn ->
        get conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category)
      conn           = get conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}/edit"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it updates the forum and redirects to the list of forum categories", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category, title: "Before", description: "Edit")
      conn           = put conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}", forum: @valid_attrs
      forum          = Repo.one(Forum)
      assert redirected_to(conn)     == admin_forum_category_path(conn, :index)
      assert forum.forum_category_id == forum_category.id
      assert forum.title             == @valid_attrs.title
      assert forum.description       == @valid_attrs.description
    end

    test "it does not update the forum but re-renders the edit template when posting invalid attributes", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category, title: "Before", description: "Edit")
      conn           = put conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}", forum: @invalid_attrs
      forum          = Repo.one(Forum)
      assert html_response(conn, 200)   =~ gettext("Edit Forum")
      assert forum.forum_category_id    == forum_category.id
      assert forum.title                == "Before"
      assert forum.description          == "Edit"
    end

    test "it does not update the forum but shows a 404 error when posting an invalid forum_category_id", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, title: "Before", description: "Edit")

      assert_error_sent :not_found, fn ->
        put conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}", forum: @valid_attrs
      end

      forum = Repo.one(Forum)
      refute forum.forum_category_id    == forum_category.id
      assert forum.title                == "Before"
      assert forum.description          == "Edit"
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent :not_found, fn ->
        put conn, "/admin/forum_categories/#{forum_category.id}/forums/1", forum: @valid_attrs
      end
    end
  end

  describe "update/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not update the forum but shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category, title: "Before", description: "Edit")
      assert_error_sent 403, fn ->
        put conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}", forum: @valid_attrs
      end
      forum = Repo.one(Forum)
      assert forum.forum_category_id == forum_category.id
      assert forum.title             == "Before"
      assert forum.description       == "Edit"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the forum but redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category, title: "Before", description: "Edit")
      conn           = put conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}", forum: @valid_attrs
      forum          = Repo.one(Forum)
      assert redirected_to(conn)        =~ session_path(conn, :new)
      assert forum.forum_category_id    == forum_category.id
      assert forum.title                == "Before"
      assert forum.description          == "Edit"
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it deletes the forum and redirects to the list of forum categories", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category)
      conn           = delete conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}"
      assert redirected_to(conn) == admin_forum_category_path(conn, :index)
      refute Repo.one(Forum)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent :not_found, fn ->
        delete conn, "/admin/forum_categories/#{forum_category.id}/forums/1"
      end
    end

    test "it does not delete the forum but shows a 404 error when providing an invalid forum_category_id", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum)
      assert_error_sent :not_found, fn ->
        delete conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}"
      end
      assert Repo.one(Forum)
    end
  end

  describe "delete/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not delete the forum but shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category)
      assert_error_sent 403, fn ->
        delete conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}"
      end
      assert Repo.one(Forum)
    end
  end

  describe "delete/2 when not signed in" do
    test "it does not delete the forum category but redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      forum          = insert(:forum, forum_category: forum_category)
      conn           = delete conn, "/admin/forum_categories/#{forum_category.id}/forums/#{forum.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert Repo.one(Forum)
    end
  end
end
