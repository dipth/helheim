defmodule Helheim.ForumControllerTest do
  use Helheim.ConnCase

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/forums"
      assert html_response(conn, 200)
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
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      forum = insert(:forum)
      conn = get conn, "/forums/#{forum.id}"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
