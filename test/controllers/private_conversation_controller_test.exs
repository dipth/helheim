defmodule Helheim.PrivateConversationControllerTest do
  use Helheim.ConnCase
  alias Helheim.PrivateMessage

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
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/private_conversations"
      assert redirected_to(conn) == session_path(conn, :new)
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

    test "it shows an error page if you supply your own user id", %{conn: conn, user: user} do
      assert_error_sent :not_found, fn ->
        get conn, "/private_conversations/#{user.id}"
      end
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
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      other_user = insert(:user)
      conn = get conn, "/private_conversations/#{other_user.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # helpers
  defp insert_message(sender, recipient, body) do
    conversation_id = PrivateMessage.calculate_conversation_id(sender, recipient)
    insert(:private_message, conversation_id: conversation_id, sender: sender, recipient: recipient, body: body)
  end
end