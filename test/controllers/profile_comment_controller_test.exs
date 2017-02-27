defmodule Helheim.ProfileCommentControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.ProfileCommentService

  @post_attrs %{foo: "bar"}
  @call_attrs %{"foo" => "bar"}

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

    test "it supports showing comments where the author is deleted", %{conn: conn} do
      comment = insert(:profile_comment, author: nil, body: "Comment with deleted user")
      profile = comment.profile
      conn = get conn, "/profiles/#{profile.id}/comments"
      assert html_response(conn, 200) =~ "Comment with deleted user"
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
    setup [:create_and_sign_in_user, :create_profile]

    test_with_mock "it redirects to the profile comments page with a success flash message when successfull", %{conn: conn, user: user, profile: profile},
      ProfileCommentService, [], [insert: fn(_attrs,_author,_profile) -> {:ok, %{comment: %{}, notification: %{}}} end] do

      conn = post conn, "/profiles/#{profile.id}/comments", comment: @post_attrs
      assert called ProfileCommentService.insert(@call_attrs, user, profile)
      assert redirected_to(conn) == public_profile_comment_path(conn, :index, profile.id)
      assert get_flash(conn, :success) == gettext("Comment created successfully")
    end

    test_with_mock "it redirects to the profile comments page with an error flash message when unsuccessfull", %{conn: conn, user: user, profile: profile},
      ProfileCommentService, [], [insert: fn(_attrs,_author,_profile) -> {:error, :comment, %{}, []} end] do

      conn = post conn, "/profiles/#{profile.id}/comments", comment: @post_attrs
      assert called ProfileCommentService.insert(@call_attrs, user, profile)
      assert redirected_to(conn) == public_profile_comment_path(conn, :index, profile.id)
      assert get_flash(conn, :error) == gettext("Unable to create comment")
    end

    test_with_mock "it does not invoke the ProfileCommentService if the profile does not exist but instead shows a 404 error", %{conn: conn},
      ProfileCommentService, [], [insert: fn(_attrs,_author,_profile) -> raise("ProfileCommentService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/profiles/1/comments", comment: @post_attrs
      end
    end
  end

  describe "create/2 when not signed in" do
    setup [:create_profile]

    test_with_mock "it does not invoke the ProfileCommentService", %{conn: conn, profile: profile},
      ProfileCommentService, [], [insert: fn(_attrs,_author,_profile) -> raise("ProfileCommentService was called!") end] do

      post conn, "/profiles/#{profile.id}/comments", comment: @post_attrs
    end

    test "it redirects to the login page", %{conn: conn, profile: profile} do
      conn = post conn, "/profiles/#{profile.id}/comments", comment: @post_attrs
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  defp create_profile(_context) do
    [profile: insert(:user)]
  end
end
