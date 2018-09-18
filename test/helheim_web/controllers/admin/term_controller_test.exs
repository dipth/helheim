defmodule HelheimWeb.Admin.TermControllerTest do
  use HelheimWeb.ConnCase
  alias Helheim.Repo
  alias Helheim.Term

  @valid_attrs %{body: "Foo Bar", published: true}
  @invalid_attrs %{body: "", published: true}

  ##############################################################################
  # index/2
  describe "index/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/admin/terms"
      assert html_response(conn, 200) =~ gettext("Terms")
    end
  end

  describe "index/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        get conn, "/admin/terms"
      end
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/admin/terms"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # new/2
  describe "new/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/admin/terms/new"
      assert html_response(conn, 200) =~ gettext("New Terms")
    end
  end

  describe "new/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        get conn, "/admin/terms/new"
      end
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/admin/terms/new"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it creates a term and redirects to the list of terms", %{conn: conn} do
      conn = post conn, "/admin/terms", term: @valid_attrs
      term = Repo.one(Term)
      assert redirected_to(conn) == admin_term_path(conn, :index)
      assert term.body           == @valid_attrs.body
    end

    test "it does not create a term but re-renders the new template when posting invalid attributes", %{conn: conn} do
      conn = post conn, "/admin/terms", term: @invalid_attrs
      refute Repo.one(Term)
      assert html_response(conn, 200) =~ gettext("New Terms")
    end
  end

  describe "create/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not create a term but shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        post conn, "/admin/terms", term: @valid_attrs
      end
      refute Repo.one(Term)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a term but redirects to the sign in page", %{conn: conn} do
      conn = post conn, "/admin/terms", term: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
      refute Repo.one(Term)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response when providing a valid id", %{conn: conn} do
      term = insert(:term)
      conn = get conn, "/admin/terms/#{term.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit Terms")
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/admin/terms/1/edit"
      end
    end
  end

  describe "edit/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      term = insert(:term)
      assert_error_sent 403, fn ->
        get conn, "/admin/terms/#{term.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      term = insert(:term)
      conn = get conn, "/admin/terms/#{term.id}/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it updates the term and redirects to the list of terms", %{conn: conn} do
      term = insert(:term, body: "Before Edit")
      conn = put conn, "/admin/terms/#{term.id}", term: @valid_attrs
      term = Repo.one(Term)
      assert redirected_to(conn) == admin_term_path(conn, :index)
      assert term.body           == @valid_attrs.body
    end

    test "it does not update the term but re-renders the edit template when posting invalid attributes", %{conn: conn} do
      term = insert(:term, body: "Before Edit")
      conn = put conn, "/admin/terms/#{term.id}", term: @invalid_attrs
      term = Repo.one(Term)
      assert html_response(conn, 200) =~ gettext("Edit Terms")
      assert term.body                == "Before Edit"
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        put conn, "/admin/terms/1", term: @valid_attrs
      end
    end
  end

  describe "update/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not update the term but shows a 401 error", %{conn: conn} do
      term = insert(:term, body: "Before Edit")
      assert_error_sent 403, fn ->
        put conn, "/admin/terms/#{term.id}", term: @valid_attrs
      end
      term = Repo.one(Term)
      assert term.body == "Before Edit"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the term but redirects to the sign in page", %{conn: conn} do
      term = insert(:term, body: "Before Edit")
      conn = put conn, "/admin/terms/#{term.id}", term: @valid_attrs
      term = Repo.one(Term)
      assert redirected_to(conn) == session_path(conn, :new)
      assert term.body           == "Before Edit"
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it deletes the term and redirects to the list of terms", %{conn: conn} do
      term = insert(:term)
      conn = delete conn, "/admin/terms/#{term.id}"
      assert redirected_to(conn) == admin_term_path(conn, :index)
      refute Repo.one(Term)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        delete conn, "/admin/terms/1"
      end
    end
  end

  describe "delete/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it does not delete the term but shows a 401 error", %{conn: conn} do
      term = insert(:term)
      assert_error_sent 403, fn ->
        delete conn, "/admin/terms/#{term.id}"
      end
      assert Repo.one(Term)
    end
  end

  describe "delete/2 when not signed in" do
    test "it does not delete the term but redirects to the sign in page", %{conn: conn} do
      term = insert(:term)
      conn = delete conn, "/admin/terms/#{term.id}"
      assert redirected_to(conn) == session_path(conn, :new)
      assert Repo.one(Term)
    end
  end
end
