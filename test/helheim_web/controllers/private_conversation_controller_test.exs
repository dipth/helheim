defmodule HelheimWeb.PrivateConversationControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.PrivateMessage
  alias Helheim.User

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/private_conversations"
      assert html_response(conn, 200)
    end

    test "it shows only conversations that the current user participates in", %{conn: conn, user: user_a} do
      user_b = insert(:user)
      user_c = insert(:user)
      insert_message(user_a, user_b, "Message One")
      insert_message(user_a, user_c, "Message Two")
      insert_message(user_b, user_c, "Message Three")
      conn = get conn, "/private_conversations"
      assert conn.resp_body =~ "Message One"
      assert conn.resp_body =~ "Message Two"
      refute conn.resp_body =~ "Message Three"
    end

    test "it supports showing conversations where the other user has been deleted", %{conn: conn, user: user} do
      partner = insert(:user)
      insert_message(user, partner, "Message With Deleted User")
      Repo.delete!(partner)
      conn = get conn, "/private_conversations"
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Message With Deleted User"
    end

    test "it does not show conversations sent by the current user and hidden by the sender", %{conn: conn, user: user} do
      partner = insert(:user)
      insert_message(user, partner, "Test conversation", DateTime.utc_now, nil)
      conn = get conn, "/private_conversations"
      assert html_response(conn, 200)
      refute conn.resp_body =~ "Test conversation"
    end

    test "it does not show conversations recieved by the current user and hidden by the recipient", %{conn: conn, user: user} do
      partner = insert(:user)
      insert_message(partner, user, "Test conversation", nil, DateTime.utc_now)
      conn = get conn, "/private_conversations"
      assert html_response(conn, 200)
      refute conn.resp_body =~ "Test conversation"
    end

    test "it shows conversations sent by the current user and hidden by the recipient", %{conn: conn, user: user} do
      partner = insert(:user)
      insert_message(user, partner, "Test conversation", nil, DateTime.utc_now)
      conn = get conn, "/private_conversations"
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Test conversation"
    end

    test "it shows conversations recieved by the current user and hidden by the sender", %{conn: conn, user: user} do
      partner = insert(:user)
      insert_message(partner, user, "Test conversation", DateTime.utc_now, nil)
      conn = get conn, "/private_conversations"
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Test conversation"
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/private_conversations"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when you supply a valid id of another user", %{conn: conn} do
      user = insert(:user)
      conn = get conn, "/private_conversations/#{user.id}"
      assert html_response(conn, 200) =~ gettext("Private conversation with %{username}", username: user.username)
    end

    test "it shows only messages between the current user and the specified partner", %{conn: conn, user: user_a} do
      user_b = insert(:user)
      user_c = insert(:user)
      insert_message(user_a, user_b, "Message One")
      insert_message(user_a, user_c, "Message Two")
      insert_message(user_b, user_c, "Message Three")
      conn = get conn, "/private_conversations/#{user_b.id}"
      assert conn.resp_body =~ "Message One"
      refute conn.resp_body =~ "Message Two"
      refute conn.resp_body =~ "Message Three"
    end

    test "it supports showing conversations where the other user has been deleted", %{conn: conn, user: user} do
      partner = insert(:user)
      insert_message(user, partner, "Message With Deleted User")
      Repo.delete!(partner)
      conn = get conn, "/private_conversations/#{partner.id}"
      assert html_response(conn, 200)
      assert conn.resp_body =~ "Message With Deleted User"
    end

    test_with_mock "it marks the conversation as read for the current user", %{conn: conn, user: user_a},
      PrivateMessage, [:passthrough], [mark_as_read!: fn(_conversation_id, _recipient) -> {:ok} end] do

      user_b          = insert(:user)
      conversation_id = PrivateMessage.calculate_conversation_id(user_a, user_b)
      get conn, "/private_conversations/#{user_b.id}"

      assert_called_with_pattern PrivateMessage, :mark_as_read!, fn(args) ->
        user_a_id = user_a.id
        [^conversation_id, %User{id: ^user_a_id}] = args
      end
    end

    test "it does not show the message form when the partner is blocking the current user", %{conn: conn, user: user} do
      block = insert(:block, blockee: user)
      conn = get conn, "/private_conversations/#{block.blocker.id}"
      assert html_response(conn, 200)
      refute conn.resp_body =~ gettext("Write new message:")
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      other_user = insert(:user)
      conn = get conn, "/private_conversations/#{other_user.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "hides the conversation", %{conn: conn, user: user_a},
      PrivateMessage, [:passthrough], [hide!: fn(_conversation_id, %{user: _user}) -> {:ok, 1} end] do

      user_b          = insert(:user)
      conversation_id = PrivateMessage.calculate_conversation_id(user_a, user_b)
      delete conn, "/private_conversations/#{user_b.id}"

      assert_called_with_pattern PrivateMessage, :hide!, fn(args) ->
        user_a_id = user_a.id
        [^conversation_id, %{user: %User{id: ^user_a_id}}] = args
      end
    end
  end

  describe "delete/2 when not signed in" do
    test_with_mock "does not hide the conversation and instead redirects to the sign in page", %{conn: conn},
      PrivateMessage, [:passthrough], [hide!: fn(_conversation_id, %{user: _user}) -> raise "PrivateMessage.hide! was called!" end] do

      other_user = insert(:user)
      conn = delete conn, "/private_conversations/#{other_user.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # helpers
  defp insert_message(sender, recipient, body), do: insert_message(sender, recipient, body, nil, nil)
  defp insert_message(sender, recipient, body, hidden_by_sender_at, hidden_by_recipient_at) do
    conversation_id = PrivateMessage.calculate_conversation_id(sender, recipient)
    insert(
      :private_message,
      conversation_id: conversation_id,
      sender: sender,
      recipient: recipient,
      body: body,
      hidden_by_sender_at: hidden_by_sender_at,
      hidden_by_recipient_at: hidden_by_recipient_at,
      read_at: DateTime.utc_now
    )
  end
end
