defmodule HelheimWeb.PrivateMessageControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.PrivateMessageService
  alias Helheim.User

  @post_attrs %{body: "bar"}

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user, :create_partner]

    test_with_mock "it redirects to the conversation with a success flash message when successfull", %{conn: conn, user: user, partner: partner},
      PrivateMessageService, [], [insert: fn(_sender,_recipient,_body) -> {:ok, %{private_message: %{}, notification: %{}}} end] do

      conn = post conn, "/private_conversations/#{partner.id}/messages", private_message: @post_attrs

      assert_called_with_pattern PrivateMessageService, :insert, fn(args) ->
        user_id    = user.id
        partner_id = partner.id
        [%User{id: ^user_id}, %User{id: ^partner_id}, "bar"] = args
      end
      assert redirected_to(conn) == private_conversation_path(conn, :show, partner.id)
      assert get_flash(conn, :success) == gettext("Message successfully sent")
    end

    test_with_mock "it redirects to the conversation with an error flash message when unsuccessfull", %{conn: conn, user: user, partner: partner},
      PrivateMessageService, [], [insert: fn(_sender,_recipient,_body) -> {:error, :private_message, %{}, []} end] do

      conn = post conn, "/private_conversations/#{partner.id}/messages", private_message: @post_attrs

      assert_called_with_pattern PrivateMessageService, :insert, fn(args) ->
        user_id    = user.id
        partner_id = partner.id
        [%User{id: ^user_id}, %User{id: ^partner_id}, "bar"] = args
      end
      assert redirected_to(conn) == private_conversation_path(conn, :show, partner.id)
      assert get_flash(conn, :error) == gettext("Unable to send message")
    end

    test_with_mock "it does not invoke the PrivateMessageService if the partner does not exist but instead shows a 404 error", %{conn: conn},
      PrivateMessageService, [], [insert: fn(_sender,_recipient,_body) -> raise("PrivateMessageService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/private_conversations/1/messages", private_message: @post_attrs
      end
    end

    test_with_mock "it does not invoke the PrivateMessageService if the partner is the same as the current user but instead shows a 404 error", %{conn: conn, user: user},
      PrivateMessageService, [], [insert: fn(_sender,_recipient,_body) -> raise("PrivateMessageService was called!") end] do

      assert_error_sent :not_found, fn ->
        post conn, "/private_conversations/#{user.id}/messages", private_message: @post_attrs
      end
    end

    test_with_mock "it does not invoke the PrivateMessageService if the partner is blocking the current user but instead redirects to a block page", %{conn: conn, user: user},
      PrivateMessageService, [], [insert: fn(_sender,_recipient,_body) -> raise("PrivateMessageService was called!") end] do

      block = insert(:block, blockee: user)
      conn  = post conn, "/private_conversations/#{block.blocker.id}/messages", private_message: @post_attrs
      assert redirected_to(conn) == block_path(conn, :show, block.blocker)
    end
  end

  describe "create/2 when not signed in" do
    setup [:create_partner]

    test_with_mock "it does not invoke the PrivateMessageService", %{conn: conn, partner: partner},
      PrivateMessageService, [], [insert: fn(_sender,_recipient,_body) -> raise("PrivateMessageService was called!") end] do

      post conn, "/private_conversations/#{partner.id}/messages", private_message: @post_attrs
    end

    test "it redirects to the login page", %{conn: conn, partner: partner} do
      conn = post conn, "/private_conversations/#{partner.id}/messages", private_message: @post_attrs
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  defp create_partner(_context) do
    [partner: insert(:user)]
  end
end
