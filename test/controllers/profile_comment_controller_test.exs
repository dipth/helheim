defmodule Helheim.ProfileCommentControllerTest do
  use Helheim.ConnCase
  alias Helheim.Comment

  @valid_attrs %{body: "Body Text"}
  @invalid_attrs %{body: ""}

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successfull response", %{conn: conn} do
      profile = insert(:user)
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert html_response(conn, 200)
    end

    test "it only shows comments for the specified profile", %{conn: conn} do
      comment_1 = insert(:profile_comment, body: "Comment 1")
      comment_2 = insert(:profile_comment, body: "Comment 2")
      profile = comment_1.profile
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert conn.resp_body =~ comment_1.body
      refute conn.resp_body =~ comment_2.body
    end

    test "it redirects to an error page when supplying an non-existing profile id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/profiles/1/comments"
      end
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the login page", %{conn: conn} do
      profile = insert(:user)
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new comment for the profile with the currently signed in user as the author and redirects back to the comments page for the profile", context = %{conn: conn} do
      profile = insert(:user)
      conn = post conn, "/profiles/#{profile.id}/comments", comment: @valid_attrs
      comment = Repo.one(Comment)
      assert comment.author_id == context[:user].id
      assert comment.profile_id == profile.id
      assert comment.body == @valid_attrs.body
      assert redirected_to(conn) == public_profile_comment_path(conn, :index, profile.id)
    end

    test "it does not create any comments when posting invalid attributes", %{conn: conn} do
      profile = insert(:user)
      post conn, "/profiles/#{profile.id}/comments", comment: @invalid_attrs
      refute Repo.one(Comment)
    end

    test "it does not create any comments if the profile does not exist but instead shows a 404 error", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        post conn, "/profiles/1/comments", comment: @valid_attrs
      end
      refute Repo.one(Comment)
    end

    test "it does not allow spoofing the author", context = %{conn: conn} do
      profile = insert(:user)
      post conn, "/profiles/#{profile.id}/comments", comment: Map.merge(@valid_attrs, %{author_id: profile.id})
      comment = Repo.one(Comment)
      assert comment.author_id == context[:user].id
    end

    test "it trims whitespace from the body", %{conn: conn} do
      profile = insert(:user)
      post conn, "/profiles/#{profile.id}/comments", comment: Map.merge(@valid_attrs, %{body: "   Foo   "})
      comment = Repo.one(Comment)
      assert comment.body == "Foo"
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create any comments", %{conn: conn} do
      profile = insert(:user)
      post conn, "/profiles/#{profile.id}/comments", comment: @valid_attrs
      refute Repo.one(Comment)
    end

    test "it redirects to the login page", %{conn: conn} do
      profile = insert(:user)
      conn = post conn, "/profiles/#{profile.id}/comments", comment: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
