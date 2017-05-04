defmodule Helheim.ForumTopicControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.ForumTopic
  alias Helheim.Forum

  @valid_attrs %{body: "Body Text", title: "Title String"}
  @invalid_attrs %{body: "   ", title: "   "}

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when specifying a valid forum_id", %{conn: conn} do
      forum = insert(:forum)
      conn  = get conn, "/forums/#{forum.id}/forum_topics/new"
      assert html_response(conn, 200) =~ gettext("Create new topic")
    end

    test "it redirects to an error page when supplying an non-existing forum_id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/forums/1/forum_topics/new"
      end
    end

    test_with_mock "it redirects back to the forum if the forum is locked", %{conn: conn},
      Forum, [:passthrough], [locked_for?: fn(_forum, _user) -> true end] do

      forum = insert(:forum)
      conn  = get conn, "/forums/#{forum.id}/forum_topics/new"
      assert redirected_to(conn) == forum_path(conn, :show, forum)
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      forum = insert(:forum)
      conn  = get conn, "/forums/#{forum.id}/forum_topics/new"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new forum topic and associates it with the current user and the specified forum", %{conn: conn, user: user} do
      forum = insert(:forum)
      conn  = post conn, "/forums/#{forum.id}/forum_topics", forum_topic: @valid_attrs
      topic = Repo.one(ForumTopic)
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, forum, topic)
      assert topic.forum_id == forum.id
      assert topic.user_id  == user.id
      assert topic.title    == @valid_attrs.title
      assert topic.body     == @valid_attrs.body
    end

    test "it does not create a forum topic but redirects to an error page when supplying an non-existing forum_id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        post conn, "/forums/1/forum_topics", forum_topic: @valid_attrs
      end
      refute Repo.one(ForumTopic)
    end

    test "it does not create a forum topic but re-renders the new template when posting invalid attrs", %{conn: conn} do
      forum = insert(:forum)
      conn  = post conn, "/forums/#{forum.id}/forum_topics", forum_topic: @invalid_attrs
      refute Repo.one(ForumTopic)
      assert html_response(conn, 200) =~ gettext("Create new topic")
    end

    test_with_mock "it does not create a forum topic but redirects back to the forum if the forum is locked", %{conn: conn},
      Forum, [:passthrough], [locked_for?: fn(_forum, _user) -> true end] do

      forum = insert(:forum)
      conn  = post conn, "/forums/#{forum.id}/forum_topics", forum_topic: @invalid_attrs
      refute Repo.one(ForumTopic)
      assert redirected_to(conn) == forum_path(conn, :show, forum)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a forum topic but redirects to the sign in page", %{conn: conn} do
      forum = insert(:forum)
      conn  = post conn, "/forums/#{forum.id}/forum_topics", forum_topic: @valid_attrs
      assert redirected_to(conn) == session_path(conn, :new)
      refute Repo.one(ForumTopic)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when specifying a valid forum_id and id", %{conn: conn} do
      topic = insert(:forum_topic, title: "What a topic!")
      conn  = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert html_response(conn, 200) =~ topic.title
    end

    test "it redirects to an error page when supplying an non-existing forum_id", %{conn: conn} do
      topic = insert(:forum_topic)
      assert_error_sent :not_found, fn ->
        get conn, "/forums/#{topic.forum.id + 1}/forum_topics/#{topic.id}"
      end
    end

    test "it redirects to an error page when supplying an non-existing id", %{conn: conn} do
      topic = insert(:forum_topic)
      assert_error_sent :not_found, fn ->
        get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id + 1}"
      end
    end

    test "it only shows replies to the specifed topic", %{conn: conn} do
      topic   = insert(:forum_topic)
      reply_1 = insert(:forum_reply, forum_topic: topic, body: "Reply A")
      reply_2 = insert(:forum_reply, body: "Reply B")
      conn    = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert conn.resp_body =~ reply_1.body
      refute conn.resp_body =~ reply_2.body
    end

    test "it supports showing topics where the user of the topic is deleted", %{conn: conn} do
      topic = insert(:forum_topic, user: nil, title: "Topic with deleted user")
      conn  = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert html_response(conn, 200) =~ "Topic with deleted user"
    end

    test "it supports showing topics where the user of a recent reply is deleted", %{conn: conn} do
      reply = insert(:forum_reply, user: nil, body: "Reply with deleted user")
      topic = reply.forum_topic
      conn  = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert html_response(conn, 200) =~ "Reply with deleted user"
    end

    test "it only shows the actual topic on the first page of the replies", %{conn: conn, user: user} do
      topic = insert(:forum_topic, body: "What a topic!")
      insert_list(27, :forum_reply, forum_topic: topic, user: user)
      conn = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert conn.resp_body =~ topic.body
      conn = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}?page=2"
      refute conn.resp_body =~ topic.body
    end

    test "it only shows the reply form on the last page of the replies", %{conn: conn, user: user} do
      topic = insert(:forum_topic)
      insert_list(27, :forum_reply, forum_topic: topic, user: user)
      conn = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      refute conn.resp_body =~ gettext("Submit new reply")
      conn = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}?page=2"
      assert conn.resp_body =~ gettext("Submit new reply")
    end

    test_with_mock "it allows showing a topic that is locked", %{conn: conn},
      Forum, [:passthrough], [locked_for?: fn(_forum, _user) -> true end] do

      topic = insert(:forum_topic, title: "What a topic!")
      conn  = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert html_response(conn, 200) =~ topic.title
    end

    test "redirects to the last possible page when specifying 'last' as page number", %{conn: conn} do
      topic = insert(:forum_topic)
      insert_list(27, :forum_reply, forum_topic: topic)
      conn = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}?page=last"
      assert redirected_to(conn) == "/forums/#{topic.forum.id}/forum_topics/#{topic.id}?page=2"
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      topic = insert(:forum_topic)
      conn  = get conn, "/forums/#{topic.forum.id}/forum_topics/#{topic.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it returns a successful response when specifying a valid forum_id and id and if the topic is editable by the user", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      topic = insert(:forum_topic)
      forum = topic.forum
      conn  = get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit topic")
    end

    test_with_mock "it redirects to an error page when supplying an non-existing forum_id", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      assert_error_sent :not_found, fn ->
        topic = insert(:forum_topic)
        forum = topic.forum
        get conn, "/forums/#{forum.id + 1}/forum_topics/#{topic.id}/edit"
      end
    end

    test_with_mock "it redirects to an error page when supplying an non-existing id", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      assert_error_sent :not_found, fn ->
        topic = insert(:forum_topic)
        forum = topic.forum
        get conn, "/forums/#{forum.id}/forum_topics/#{topic.id + 1}/edit"
      end
    end

    test_with_mock "it redirects back to the topic if it is not editable by the user", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> false end] do

      topic = insert(:forum_topic)
      forum = topic.forum
      conn  = get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/edit"
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, forum, topic)
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      topic = insert(:forum_topic)
      forum = topic.forum
      conn  = get conn, "/forums/#{forum.id}/forum_topics/#{topic.id}/edit"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it updates the topic and redirects back to the topic", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      user  = insert(:user)
      topic = insert(:forum_topic, user: user, title: "Before", body: "Edit")
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}", forum_topic: @valid_attrs
      topic = Repo.one(ForumTopic)
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, forum, topic)
      assert topic.forum_id      == forum.id
      assert topic.user_id       == user.id
      assert topic.title         == @valid_attrs.title
      assert topic.body          == @valid_attrs.body
    end

    test_with_mock "it does not update the topic but re-renders the edit template when posting invalid attrs", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      topic = insert(:forum_topic, title: "Before", body: "Edit")
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}", forum_topic: @invalid_attrs
      topic = Repo.one(ForumTopic)
      assert html_response(conn, 200) =~ gettext("Edit topic")
      assert topic.title == "Before"
      assert topic.body  == "Edit"
    end

    test_with_mock "does not update the topic but redirects to an error page when supplying an non-existing forum_id", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      topic = insert(:forum_topic, title: "Before", body: "Edit")
      forum = topic.forum
      assert_error_sent :not_found, fn ->
        put conn, "/forums/#{forum.id + 1}/forum_topics/#{topic.id}", forum_topic: @valid_attrs
      end
      topic = Repo.one(ForumTopic)
      assert topic.title == "Before"
      assert topic.body  == "Edit"
    end

    test_with_mock "it does not update the topic but redirects to an error page when supplying an non-existing id", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> true end] do

      topic = insert(:forum_topic, title: "Before", body: "Edit")
      forum = topic.forum
      assert_error_sent :not_found, fn ->
        put conn, "/forums/#{forum.id}/forum_topics/#{topic.id + 1}", forum_topic: @valid_attrs
      end
      topic = Repo.one(ForumTopic)
      assert topic.title == "Before"
      assert topic.body  == "Edit"
    end

    test_with_mock "it does not update the topic but redirects back to the topic if it is not editable by the user", %{conn: conn},
      ForumTopic, [:passthrough], [editable_by?: fn(_topic, _user) -> false end] do

      topic = insert(:forum_topic, title: "Before", body: "Edit")
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}", forum_topic: @valid_attrs
      topic = Repo.one(ForumTopic)
      assert redirected_to(conn) == forum_forum_topic_path(conn, :show, forum, topic)
      assert topic.title         == "Before"
      assert topic.body          == "Edit"
    end
  end

  describe "update/2 when not signed in" do
    test "it does not update the topic but redirects to the sign in page", %{conn: conn} do
      topic = insert(:forum_topic, title: "Before", body: "Edit")
      forum = topic.forum
      conn  = put conn, "/forums/#{forum.id}/forum_topics/#{topic.id}", forum_topic: @valid_attrs
      topic = Repo.one(ForumTopic)
      assert redirected_to(conn) == session_path(conn, :new)
      assert topic.title         == "Before"
      assert topic.body          == "Edit"
    end
  end
end
