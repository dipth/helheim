defmodule HelheimWeb.FriendshipControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.Friendship

  ##############################################################################
  # index/2 for your own list
  describe "index/2 for your own list when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/contacts"
      assert html_response(conn, 200)
    end

    test "it only shows pending friendships recieved by the current user", %{conn: conn, user: user} do
      friendship1 = insert(:friendship_request, recipient: user)
      friendship2 = insert(:friendship_request)
      conn        = get conn, "/contacts"
      assert conn.resp_body =~ friendship1.sender.username
      refute conn.resp_body =~ friendship2.sender.username
    end

    test "it only shows accepted friendships involving the current user", %{conn: conn, user: user} do
      friendship1 = insert(:friendship, recipient: user)
      friendship2 = insert(:friendship, sender: user)
      friendship3 = insert(:friendship)
      conn        = get conn, "/contacts"
      assert conn.resp_body =~ friendship1.sender.username
      assert conn.resp_body =~ friendship2.recipient.username
      refute conn.resp_body =~ friendship3.sender.username
      refute conn.resp_body =~ friendship3.recipient.username
    end
  end

  describe "index/2 for your own list when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/contacts"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # index/2 for someone elses list
  describe "index/2 for someone elses list when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      profile = insert(:user)
      conn    = get conn, "/profiles/#{profile.id}/contacts"
      assert html_response(conn, 200)
    end

    test "it does not show pending requests received by the user", %{conn: conn} do
      friendship = insert(:friendship_request)
      conn       = get conn, "/profiles/#{friendship.recipient.id}/contacts"
      refute conn.resp_body =~ friendship.sender.username
    end

    test "it only shows accepted friendships involving the user", %{conn: conn} do
      profile     = insert(:user)
      friendship1 = insert(:friendship, recipient: profile)
      friendship2 = insert(:friendship, sender: profile)
      friendship3 = insert(:friendship)
      conn        = get conn, "/profiles/#{profile.id}/contacts"
      assert conn.resp_body =~ friendship1.sender.username
      assert conn.resp_body =~ friendship2.recipient.username
      refute conn.resp_body =~ friendship3.sender.username
      refute conn.resp_body =~ friendship3.recipient.username
    end
  end

  describe "index/2 for someone elses list when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      profile = insert(:user)
      conn    = get conn, "/profiles/#{profile.id}/contacts"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it accepts a friendship request from the the specified user to the current user and redirects to the friend list", %{conn: conn, user: recipient},
      Friendship, [:passthrough], [accept_friendship!: fn(_recipient, _sender) -> {:ok, nil} end] do

      sender = Repo.get!(Helheim.User, insert(:user).id)
      conn   = post conn, "/profiles/#{sender.id}/contact"
      assert called Friendship.accept_friendship!(recipient, sender)
      assert redirected_to(conn) == friendship_path(conn, :index)
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not accept any friendship request but redirects to the login page", %{conn: conn},
      Friendship, [:passthrough], [accept_friendship!: fn(_recipient, _sender) -> raise("accept_friendship!/2 was called!") end] do

      sender = insert(:user)
      conn   = post conn, "/profiles/#{sender.id}/contact"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it cancels a friendship between the specified user and the current user and redirects to the friend list", %{conn: conn, user: user_a},
      Friendship, [:passthrough], [cancel_friendship!: fn(_user_a, _user_b) -> {:ok, nil} end] do

      user_b = Repo.get!(Helheim.User, insert(:user).id)
      conn   = delete conn, "/profiles/#{user_b.id}/contact"
      assert called Friendship.cancel_friendship!(user_a, user_b)
      assert redirected_to(conn) == friendship_path(conn, :index)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not cancel any friendship but redirects to the login page", %{conn: conn},
      Friendship, [:passthrough], [cancel_friendship!: fn(_recipient, _sender) -> raise("cancel_friendship!/2 was called!") end] do

      user_b = insert(:user)
      conn   = delete conn, "/profiles/#{user_b.id}/contact"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
