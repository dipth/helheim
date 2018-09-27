defmodule HelheimWeb.Admin.CalendarEventControllerTest do
  use HelheimWeb.ConnCase
  alias Helheim.Repo
  alias Helheim.CalendarEvent

  ##############################################################################
  # index/2
  describe "index/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin]

    test "it returns a successful response containing only pending calendar events", %{conn: conn} do
      insert(:calendar_event, title: "A pending event", approved_at: nil, rejected_at: nil)
      insert(:calendar_event, title: "A rejected event", approved_at: nil, rejected_at: DateTime.utc_now)
      insert(:calendar_event, title: "An approved event", approved_at: DateTime.utc_now, rejected_at: nil)
      conn = get conn, "/admin/calendar_events"
      assert body = html_response(conn, 200)
      assert body =~ "A pending event"
      refute body =~ "A rejected event"
      refute body =~ "An approved event"
    end
  end

  describe "index/2 when signed in as a user" do
    setup [:create_and_sign_in_user]

    test "it shows a 401 error", %{conn: conn} do
      assert_error_sent 403, fn ->
        get conn, "/admin/calendar_events"
      end
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/admin/calendar_events"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin, :create_calendar_event]

    test "it returns a successful response", %{conn: conn, calendar_event: calendar_event} do
      conn = get conn, "/admin/calendar_events/#{calendar_event.id}"
      assert html_response(conn, 200) =~ calendar_event.title
    end
  end

  describe "show/2 when signed in as a user" do
    setup [:create_and_sign_in_user, :create_calendar_event]

    test "it shows a 401 error", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent 403, fn ->
        get conn, "/admin/calendar_events/#{calendar_event.id}"
      end
    end
  end

  describe "show/2 when not signed in" do
    setup [:create_calendar_event]

    test "it redirects to the sign in page", %{conn: conn, calendar_event: calendar_event} do
      conn = get conn, "/admin/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin, :create_pending_calendar_event]

    test "it approves the event and redirects to the list of events", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/admin/calendar_events/#{calendar_event.id}"
      calendar_event = Repo.get!(CalendarEvent, calendar_event.id)
      assert redirected_to(conn) == admin_calendar_event_path(conn, :index)
      assert CalendarEvent.approved?(calendar_event)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        put conn, "/admin/calendar_events/#{calendar_event.id + 1}"
      end
    end
  end

  describe "update/2 when signed in as a user" do
    setup [:create_and_sign_in_user, :create_pending_calendar_event]

    test "it does not approve the event but shows a 401 error", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent 403, fn ->
        put conn, "/admin/calendar_events/#{calendar_event.id}"
      end
      calendar_event = Repo.get!(CalendarEvent, calendar_event.id)
      assert CalendarEvent.pending?(calendar_event)
    end
  end

  describe "update/2 when not signed in" do
    setup [:create_pending_calendar_event]

    test "it does not approve the event but redirects to the sign in page", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/admin/calendar_events/#{calendar_event.id}"
      calendar_event = Repo.get!(CalendarEvent, calendar_event.id)
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert CalendarEvent.pending?(calendar_event)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin, :create_pending_calendar_event]

    test "it rejects the event and redirects to the list of events", %{conn: conn, calendar_event: calendar_event} do
      conn = delete conn, "/admin/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) == admin_calendar_event_path(conn, :index)
      calendar_event = Repo.get!(CalendarEvent, calendar_event.id)
      assert CalendarEvent.rejected?(calendar_event)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        delete conn, "/admin/calendar_events/#{calendar_event.id + 1}"
      end
    end
  end

  describe "delete/2 when signed in as a user" do
    setup [:create_and_sign_in_user, :create_pending_calendar_event]

    test "it does not reject the event but shows a 401 error", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent 403, fn ->
        delete conn, "/admin/calendar_events/#{calendar_event.id}"
      end
      calendar_event = Repo.get!(CalendarEvent, calendar_event.id)
      assert CalendarEvent.pending?(calendar_event)
    end
  end

  describe "delete/2 when not signed in" do
    setup [:create_pending_calendar_event]

    test "it does not reject the event but redirects to the sign in page", %{conn: conn, calendar_event: calendar_event} do
      conn = delete conn, "/admin/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
      calendar_event = Repo.get!(CalendarEvent, calendar_event.id)
      assert CalendarEvent.pending?(calendar_event)
    end
  end

  ##############################################################################
  # SETUP
  defp create_calendar_event(_context) do
    calendar_event = insert(:calendar_event)
    {:ok, calendar_event: calendar_event}
  end

  defp create_pending_calendar_event(_context) do
    calendar_event = insert(:calendar_event, approved_at: nil, rejected_at: nil)
    {:ok, calendar_event: calendar_event}
  end
end
