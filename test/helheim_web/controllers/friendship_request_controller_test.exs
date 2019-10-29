defmodule HelheimWeb.FriendshipRequestControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.Friendship
  alias Helheim.User

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it creates a friendship request from the current user to the specified user and redirects to the specified users profile page", %{conn: conn, user: sender},
      Friendship, [:passthrough], [request_friendship!: fn(_sender, _recipient) -> {:ok, nil} end] do

      recipient = insert(:user)
      conn      = post conn, "/profiles/#{recipient.id}/contact_request"

      assert_called_with_pattern Friendship, :request_friendship!, fn(args) ->
        sender_id    = sender.id
        recipient_id = recipient.id
        [%User{id: ^sender_id}, %User{id: ^recipient_id}] = args
      end
      assert redirected_to(conn) == public_profile_path(conn, :show, recipient)
    end
  end

  describe "create/2 when not signed in" do
    test_with_mock "it does not create a friendship request but redirects to the login page", %{conn: conn},
      Friendship, [:passthrough], [request_friendship!: fn(_sender, _recipient) -> raise("request_friendship!/2 was called!") end] do

      recipient = insert(:user)
      conn      = post conn, "/profiles/#{recipient.id}/contact_request"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it rejects a friendship request from the specified user to the current user and redirects to the friend list", %{conn: conn, user: recipient},
      Friendship, [:passthrough], [reject_friendship!: fn(_recipient, _sender) -> {:ok, nil} end] do

      sender = insert(:user)
      conn   = delete conn, "/profiles/#{sender.id}/contact_request"

      assert_called_with_pattern Friendship, :reject_friendship!, fn(args) ->
        recipient_id = recipient.id
        sender_id    = sender.id
        [%User{id: ^recipient_id}, %User{id: ^sender_id}] = args
      end
      assert redirected_to(conn) == friendship_path(conn, :index)
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "it does not reject any friendship requests but redirects to the login page", %{conn: conn},
      Friendship, [:passthrough], [reject_friendship!: fn(_recipient, _sender) -> raise("reject_friendship!/2 was called!") end] do

      sender = insert(:user)
      conn   = delete conn, "/profiles/#{sender.id}/contact_request"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
