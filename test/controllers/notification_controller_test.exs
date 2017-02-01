defmodule Helheim.NotificationControllerTest do
  use Helheim.ConnCase
  alias Helheim.Notification

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it redirects to the path of the notification", %{conn: conn, user: user} do
      notification = insert(:notification, user: user, path: "/foo/bar?baz")
      conn = get conn, "/notifications/#{notification.id}"
      assert redirected_to(conn) == "/foo/bar?baz"
    end

    test "it marks the notification as read", %{conn: conn, user: user} do
      notification = insert(:notification, user: user, read_at: nil)
      get conn, "/notifications/#{notification.id}"
      notification = Repo.get(Notification, notification.id)
      {:ok, time_diff, _, _} = Calendar.DateTime.diff(notification.read_at, DateTime.utc_now)
      assert time_diff < 10
    end

    test "it does not mark the notification as read but instead shows an error page if the notification does not belong to the current user", %{conn: conn} do
      notification = insert(:notification, read_at: nil)
      assert_error_sent :not_found, fn ->
        get conn, "/notifications/#{notification.id}"
      end
      notification = Repo.get(Notification, notification.id)
      refute notification.read_at
    end
  end

  describe "show/2 when not signed in" do
    test "it does not mark the notification as read bute instead redirects to the sign in page", %{conn: conn} do
      notification = insert(:notification, read_at: nil)
      conn = get conn, "/notifications/#{notification.id}"
      assert redirected_to(conn) == session_path(conn, :new)
      notification = Repo.get(Notification, notification.id)
      refute notification.read_at
    end
  end

  ##############################################################################
  # refresh/2
  describe "refresh/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/notifications/refresh"
      assert html_response(conn, 200)
    end

    test "it only returns notifications belonging to the user", %{conn: conn, user: user} do
      notification_1 = insert(:notification, user: user, title: "Foo Notification")
      notification_2 = insert(:notification, title: "Bar Notification")
      conn = get conn, "/notifications/refresh"
      assert conn.resp_body =~ notification_1.title
      refute conn.resp_body =~ notification_2.title
    end

    test "it only returns notifications that are unread", %{conn: conn, user: user} do
      notification_1 = insert(:notification, user: user, title: "Foo Notification")
      notification_2 = insert(:notification, user: user, title: "Bar Notification", read_at: DateTime.utc_now)
      conn = get conn, "/notifications/refresh"
      assert conn.resp_body =~ notification_1.title
      refute conn.resp_body =~ notification_2.title
    end
  end

  describe "refresh/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/notifications/refresh"
      assert redirected_to(conn) == session_path(conn, :new)
    end
  end
end
