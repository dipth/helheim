defmodule Helheim.ForumReplyControllerTest do
  use Helheim.ConnCase
  alias Helheim.ForumReply

  @valid_attrs %{body: "Body Text"}
  @invalid_attrs %{body: "   "}

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new forum reply and associates it with the current user and the specified forum topic", %{conn: conn, user: user} do
      topic = insert(:forum_topic)
      conn  = post conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}/forum_replies", forum_reply: @valid_attrs
      reply = Repo.one(ForumReply)
      assert redirected_to(conn)  == forum_forum_topic_path(conn, :show, topic.forum, topic)
      assert reply.forum_topic_id == topic.id
      assert reply.user_id        == user.id
      assert reply.body           == @valid_attrs.body
    end

    test "it does not create a forum reply but redirects to an error page when supplying an non-existing forum_id", %{conn: conn} do
      topic = insert(:forum_topic)
      assert_error_sent :not_found, fn ->
        post conn, "/forums/#{topic.forum.id + 1}/forum_topics/#{topic.id}/forum_replies", forum_reply: @valid_attrs
      end
      refute Repo.one(ForumReply)
    end

    test "it does not create a forum reply but redirects to an error page when supplying an non-existing forum_topic_id", %{conn: conn} do
      topic = insert(:forum_topic)
      assert_error_sent :not_found, fn ->
        post conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id + 1}/forum_replies", forum_reply: @valid_attrs
      end
      refute Repo.one(ForumReply)
    end

    test "it does not create a forum reply but redirects back to the topic when posting invalid attrs", %{conn: conn} do
      topic = insert(:forum_topic)
      conn  = post conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}/forum_replies", forum_reply: @invalid_attrs
      refute Repo.one(ForumReply)
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, topic.forum, topic)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a forum reply but redirects to the sign in page", %{conn: conn} do
      topic = insert(:forum_topic)
      conn  = post conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}/forum_replies", forum_reply: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
      refute Repo.one(ForumReply)
    end
  end
end
