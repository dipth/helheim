defmodule Helheim.ForumReplyControllerTest do
  use Helheim.ConnCase
  import Mock
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

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it returns a successful response", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      reply = insert(:forum_reply)
      topic = reply.forum_topic
      forum = topic.forum
      conn  = get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit reply")
    end

    test_with_mock "it redirects to an error page when supplying an non-existing forum_id", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      assert_error_sent :not_found, fn ->
        reply = insert(:forum_reply)
        topic = reply.forum_topic
        forum = topic.forum
        get conn, "/forums/#{forum.id + 1}/forum_topics/#{topic.id}/forum_replies/#{reply.id}/edit"
      end
    end

    test_with_mock "it redirects to an error page when supplying an non-existing forum_topic_id", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      assert_error_sent :not_found, fn ->
        reply = insert(:forum_reply)
        topic = reply.forum_topic
        forum = topic.forum
        get conn, "/forums/#{forum.id}/forum_topics/#{topic.id + 1}/forum_replies/#{reply.id}/edit"
      end
    end

    test_with_mock "it redirects to an error page when supplying an non-existing id", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      assert_error_sent :not_found, fn ->
        reply = insert(:forum_reply)
        topic = reply.forum_topic
        forum = topic.forum
        get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id + 1}/edit"
      end
    end

    test_with_mock "it redirects back to the topic if the reply is not editable by the user", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> false end] do

      reply = insert(:forum_reply)
      topic = reply.forum_topic
      forum = topic.forum
      conn  = get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}/edit"
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, forum, topic)
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      reply = insert(:forum_reply)
      topic = reply.forum_topic
      forum = topic.forum
      conn  = get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it updates the reply and redirects back to the topic", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      user  = insert(:user)
      reply = insert(:forum_reply, user: user, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}", forum_reply: @valid_attrs
      reply = Repo.one(ForumReply)
      assert redirected_to(conn)  == forum_forum_topic_path(conn, :show, forum, topic)
      assert reply.forum_topic_id == topic.id
      assert reply.user_id        == user.id
      assert reply.body           == @valid_attrs.body
    end

    test_with_mock "it does not update the reply but re-renders the edit template when posting invalid attrs", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      reply = insert(:forum_reply, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}", forum_reply: @invalid_attrs
      reply = Repo.one(ForumReply)
      assert html_response(conn, 200) =~ gettext("Edit reply")
      assert reply.body == "Before"
    end

    test_with_mock "does not update the reply but redirects to an error page when supplying an non-existing forum_id", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      reply = insert(:forum_reply, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      assert_error_sent :not_found, fn ->
        put conn, "/forums/#{forum.id + 1}/forum_topics/#{topic.id}/forum_replies/#{reply.id}", forum_reply: @valid_attrs
      end
      reply = Repo.one(ForumReply)
      assert reply.body == "Before"
    end

    test_with_mock "it does not update the reply but redirects to an error page when supplying an non-existing forum_topic_id", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      reply = insert(:forum_reply, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      assert_error_sent :not_found, fn ->
        put conn, "/forums/#{forum.id}/forum_topics/#{topic.id + 1}/forum_replies/#{reply.id}", forum_reply: @valid_attrs
      end
      reply = Repo.one(ForumReply)
      assert reply.body == "Before"
    end

    test_with_mock "it does not update the reply but redirects to an error page when supplying an non-existing id", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> true end] do

      reply = insert(:forum_reply, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      assert_error_sent :not_found, fn ->
        put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id + 1}", forum_reply: @valid_attrs
      end
      reply = Repo.one(ForumReply)
      assert reply.body == "Before"
    end

    test_with_mock "it does not update the reply but redirects back to the topic if it is not editable by the user", %{conn: conn},
      ForumReply, [:passthrough], [editable_by?: fn(_reply, _user) -> false end] do

      reply = insert(:forum_reply, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}", forum_reply: @valid_attrs
      reply = Repo.one(ForumReply)
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, forum, topic)
      assert reply.body          == "Before"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the reply but redirects to the sign in page", %{conn: conn} do
      reply = insert(:forum_reply, body: "Before")
      topic = reply.forum_topic
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/forum_replies/#{reply.id}", forum_reply: @valid_attrs
      reply = Repo.one(ForumReply)
      assert redirected_to(conn) == session_path(conn, :new)
      assert reply.body          == "Before"
    end
  end
end
