defmodule Helheim.Admin.ForumCategoryControllerTest do
  use Helheim.ConnCase
  alias Helheim.Repo
  alias Helheim.ForumCategory

  @valid_attrs %{title: "Foo", description: "Bar"}
  @invalid_attrs %{title: "", description: ""}

  ##############################################################################
  # index/2
  describe "index/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/admin/forum_categories"
      assert html_response(conn, 200) =~ gettext("Forum Categories")
    end
  end

  describe "index/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        get conn, "/admin/forum_categories"
      end
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/admin/forum_categories"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # new/2
  describe "new/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/admin/forum_categories/new"
      assert html_response(conn, 200) =~ gettext("New Forum Category")
    end
  end

  describe "new/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        get conn, "/admin/forum_categories/new"
      end
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/admin/forum_categories/new"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it creates a forum category and redirects to the list of forum categories", %{conn: conn} do
      conn           = post conn, "/admin/forum_categories", forum_category: @valid_attrs
      forum_category = Repo.one(ForumCategory)
      assert redirected_to(conn)        == admin_forum_category_path(conn, :index)
      assert forum_category.title       == @valid_attrs.title
      assert forum_category.description == @valid_attrs.description
    end

    test "it does not create a forum category but re-renders the new template when posting invalid attributes", %{conn: conn} do
      conn = post conn, "/admin/forum_categories", forum_category: @invalid_attrs
      refute Repo.one(ForumCategory)
      assert html_response(conn, 200) =~ gettext("New Forum Category")
    end
  end

  describe "create/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not create a forum category but shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        post conn, "/admin/forum_categories", forum_category: @valid_attrs
      end
      refute Repo.one(ForumCategory)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a forum category but redirects to the sign in page", %{conn: conn} do
      conn = post conn, "/admin/forum_categories", forum_category: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
      refute Repo.one(ForumCategory)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when providing a valid id", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = get conn, "/admin/forum_categories/#{forum_category.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Forum Category")
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/admin/forum_categories/1/edit"
      end
    end
  end

  describe "edit/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent 403, fn ->
        get conn, "/admin/forum_categories/#{forum_category.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = get conn, "/admin/forum_categories/#{forum_category.id}/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it updates the forum category and redirects to the list of forum categories", %{conn: conn} do
      forum_category = insert(:forum_category, title: "Before", description: "Edit")
      conn           = put conn, "/admin/forum_categories/#{forum_category.id}", forum_category: @valid_attrs
      forum_category = Repo.one(ForumCategory)
      assert redirected_to(conn)        == admin_forum_category_path(conn, :index)
      assert forum_category.title       == @valid_attrs.title
      assert forum_category.description == @valid_attrs.description
    end

    test "it does not update the forum category but re-renders the edit template when posting invalid attributes", %{conn: conn} do
      forum_category = insert(:forum_category, title: "Before", description: "Edit")
      conn           = put conn, "/admin/forum_categories/#{forum_category.id}", forum_category: @invalid_attrs
      forum_category = Repo.one(ForumCategory)
      assert html_response(conn, 200)   =~ gettext("Edit Forum Category")
      assert forum_category.title       == "Before"
      assert forum_category.description == "Edit"
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        put conn, "/admin/forum_categories/1", forum_category: @valid_attrs
      end
    end
  end

  describe "update/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not update the forum category but shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category, title: "Before", description: "Edit")
      assert_error_sent 403, fn ->
        put conn, "/admin/forum_categories/#{forum_category.id}", forum_category: @valid_attrs
      end
      forum_category = Repo.one(ForumCategory)
      assert forum_category.title       == "Before"
      assert forum_category.description == "Edit"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the forum category but redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category, title: "Before", description: "Edit")
      conn           = put conn, "/admin/forum_categories/#{forum_category.id}", forum_category: @valid_attrs
      forum_category = Repo.one(ForumCategory)
      assert redirected_to(conn)        == session_path(conn, :new)
      assert forum_category.title       == "Before"
      assert forum_category.description == "Edit"
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it deletes the forum category and redirects to the list of forum categories", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = delete conn, "/admin/forum_categories/#{forum_category.id}"
      assert redirected_to(conn) == admin_forum_category_path(conn, :index)
      refute Repo.one(ForumCategory)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        delete conn, "/admin/forum_categories/1"
      end
    end
  end

  describe "delete/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not delete the forum category but shows a 401 error", %{conn: conn} do
      forum_category = insert(:forum_category)
      assert_error_sent 403, fn ->
        delete conn, "/admin/forum_categories/#{forum_category.id}"
      end
      assert Repo.one(ForumCategory)
    end
  end

  describe "delete/2 when not signed in" do
    test "it does not delete the forum category but redirects to the sign in page", %{conn: conn} do
      forum_category = insert(:forum_category)
      conn           = delete conn, "/admin/forum_categories/#{forum_category.id}"
      assert redirected_to(conn) == session_path(conn, :new)
      assert Repo.one(ForumCategory)
    end
  end
end
