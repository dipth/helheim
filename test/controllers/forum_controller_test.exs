defmodule Helheim.ForumControllerTest do
  use Helheim.ConnCase
  import Mock
  alias Helheim.Forum

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/forums"
      assert html_response(conn, 200)
    end

    test "it supports showing forums where the user of the newest topic is deleted", %{conn: conn} do
      insert(:forum_topic, user: nil, title: "Topic with deleted user")
      conn = get conn, "/forums"
      assert html_response(conn, 200) =~ "Topic with deleted user"
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/forums"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when specifying a valid id", %{conn: conn} do
      forum = insert(:forum)
      conn = get conn, "/forums/#{forum.id}"
      assert html_response(conn, 200)
    end

    test "it redirects to an error page when supplying an non-existing id", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/forums/1"
      end
    end

    test "it only shows forum topics from the specified forum", %{conn: conn} do
      forum = insert(:forum)
      topic_1 = insert(:forum_topic, forum: forum, title: "Topic A")
      topic_2 = insert(:forum_topic, title: "Topic B")
      conn = get conn, "/forums/#{forum.id}"
      assert conn.resp_body =~ topic_1.title
      refute conn.resp_body =~ topic_2.title
    end

    test "it supports showing forums where the user of a recent topic is deleted", %{conn: conn} do
      forum_topic = insert(:forum_topic, user: nil, title: "Topic with deleted user")
      conn = get conn, "/forums/#{forum_topic.forum.id}"
      assert html_response(conn, 200) =~ "Topic with deleted user"
    end

    test_with_mock "it shows a `create new topic` button if the forum is not locked", %{conn: conn},
      Forum, [:passthrough], [locked_for?: fn(_forum, _user) -> false end] do

      forum = insert(:forum)
      conn  = get conn, "/forums/#{forum.id}"
      assert conn.resp_body =~ gettext("Create new topic")
    end

    test_with_mock "it does not show a `create new topic` button if the forum is locked", %{conn: conn},
      Forum, [:passthrough], [locked_for?: fn(_forum, _user) -> true end] do

      forum = insert(:forum)
      conn  = get conn, "/forums/#{forum.id}"
      refute conn.resp_body =~ gettext("Create new topic")
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      forum = insert(:forum)
      conn = get conn, "/forums/#{forum.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
