defmodule HelheimWeb.CalendarEventControllerTest do
  use HelheimWeb.ConnCase
  alias Helheim.CalendarEvent
  alias Helheim.NotificationSubscription

  @valid_attrs %{title: "My awesome event", description: "Just for testing", starts_at: "2018-08-01 12:00:00.000000", ends_at: "2018-08-01 15:00:00.000000", location: "My place!"}
  @invalid_attrs %{title: ""}

  ##############################################################################
  # index/2
  describe "index/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response containing only approved events", %{conn: conn} do
      insert(:calendar_event, title: "A pending event", approved_at: nil, rejected_at: nil)
      insert(:calendar_event, title: "A rejected event", approved_at: nil, rejected_at: DateTime.utc_now)
      insert(:calendar_event, title: "An approved event", approved_at: DateTime.utc_now, rejected_at: nil)
      conn = get conn, "/calendar_events"
      assert body = html_response(conn, 200)
      assert body =~ "An approved event"
      refute body =~ "A pending event"
      refute body =~ "A rejected event"
    end
  end

  describe "index/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/calendar_events"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # new/2
  describe "new/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/calendar_events/new"
      assert html_response(conn, 200) =~ gettext("Create event")
    end
  end

  describe "new/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/calendar_events/new"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it creates a new pending event and associates it with the signed in user when posting valid params", %{conn: conn, user: user} do
      conn = post conn, "/calendar_events", calendar_event: @valid_attrs
      calendar_event = Repo.one(CalendarEvent)
      assert calendar_event.title == @valid_attrs.title
      assert calendar_event.description == @valid_attrs.description
      assert calendar_event.user_id == user.id
      assert calendar_event.starts_at == ~N[2018-08-01 12:00:00.000000]
      assert calendar_event.ends_at == ~N[2018-08-01 15:00:00.000000]
      assert CalendarEvent.pending?(calendar_event)
      assert redirected_to(conn) == calendar_event_path(conn, :index)
    end

    test "it creates a notification subscription for the newly created event when posting valid params", %{conn: conn, user: user} do
      _conn = post conn, "/calendar_events", calendar_event: @valid_attrs
      calendar_event = Repo.one(CalendarEvent)
      sub = Repo.one(NotificationSubscription)
      assert sub.user_id == user.id
      assert sub.type == "comment"
      assert sub.calendar_event_id == calendar_event.id
      assert sub.enabled == true
    end

    test "it does not create a new event and re-renders the new template when posting invalid params", %{conn: conn} do
      conn = post conn, "/calendar_events", calendar_event: @invalid_attrs
      refute Repo.one(CalendarEvent)
      assert html_response(conn, 200) =~ gettext("Create event")
    end

    test "it is impossible to fake the user_id or approval status of an event", %{conn: conn, user: user} do
      other_user = insert(:user)
      post conn, "/calendar_events", calendar_event: Map.merge(@valid_attrs, %{user_id: other_user.id, approved_at: "2018-08-01 00:00:00.000000"})
      calendar_event = Repo.one(CalendarEvent)
      assert calendar_event.user_id == user.id
      assert CalendarEvent.pending?(calendar_event)
    end
  end

  describe "create/2 when not signed in" do
    test "it does not create a new event and instead redirects to the login page", %{conn: conn} do
      conn = post conn, "/calendar_events", calendar_event: @valid_attrs
      refute Repo.one(CalendarEvent)
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response with the id of an existing approved event", %{conn: conn} do
      calendar_event = insert(:calendar_event)
      conn = get conn, "/calendar_events/#{calendar_event.id}"
      assert html_response(conn, 200) =~ calendar_event.title
    end

    test "it redirects to an error page with the id of a non-existing event", %{conn: conn} do
      assert_error_sent :not_found, fn ->
        get conn, "/calendar_events/1"
      end
    end

    test "it redirects to an error page with the id of an existing pending event", %{conn: conn} do
      calendar_event = insert(:calendar_event, approved_at: nil, rejected_at: nil)
      assert_error_sent :not_found, fn ->
        get conn, "/calendar_events/#{calendar_event.id}"
      end
    end

    test "it redirects to an error page with the id of an existing rejected event", %{conn: conn} do
      calendar_event = insert(:calendar_event, approved_at: nil, rejected_at: DateTime.utc_now)
      assert_error_sent :not_found, fn ->
        get conn, "/calendar_events/#{calendar_event.id}"
      end
    end

    test "it supports showing comments from deleted users", %{conn: conn} do
      comment        = insert(:calendar_event_comment, author: nil)
      calendar_event = comment.calendar_event
      conn           = get conn, "/calendar_events/#{calendar_event.id}"
      assert html_response(conn, 200)
    end
  end

  describe "show/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      calendar_event = insert(:calendar_event)
      conn = get conn, "/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin, :create_calendar_event]

    test "it returns a successful response", %{conn: conn, calendar_event: calendar_event} do
      conn = get conn, "/calendar_events/#{calendar_event.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit event")
    end

    test "it redirects to an error page with the id of a non-existent event", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        get conn, "/calendar_events/#{calendar_event.id + 1}/edit"
      end
    end
  end

  describe "edit/2 when signed in as a moderator" do
    setup [:create_and_sign_in_mod, :create_calendar_event]

    test "it returns a successful response", %{conn: conn, calendar_event: calendar_event} do
      conn = get conn, "/calendar_events/#{calendar_event.id}/edit"
      assert html_response(conn, 200) =~ gettext("Edit event")
    end

    test "it redirects to an error page with the id of a non-existent event", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        get conn, "/calendar_events/#{calendar_event.id + 1}/edit"
      end
    end
  end

  describe "edit/2 when signed in as a user" do
    setup [:create_and_sign_in_user, :create_calendar_event]

    test "it shows a 401 error", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent 403, fn ->
        get conn, "/calendar_events/#{calendar_event.id}/edit"
      end
    end
  end

  describe "edit/2 when not signed in" do
    setup [:create_calendar_event]

    test "it redirects to the sign in page", %{conn: conn, calendar_event: calendar_event} do
      conn = get conn, "/calendar_events/#{calendar_event.id}/edit"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin, :create_calendar_event]

    test "it updates the event when posting valid params", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}", calendar_event: @valid_attrs
      updated_calendar_event = Repo.get(CalendarEvent, calendar_event.id)
      assert updated_calendar_event.title == @valid_attrs.title
      assert updated_calendar_event.description == @valid_attrs.description
      assert updated_calendar_event.user_id == calendar_event.user_id
      assert redirected_to(conn) == calendar_event_path(conn, :show, calendar_event)
    end

    test "it does not update the event and re-renders the edit template when posting invalid params", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}", calendar_event: @invalid_attrs
      assert html_response(conn, 200) =~ gettext("Edit event")
    end
  end

  describe "update/2 when signed in as a moderator" do
    setup [:create_and_sign_in_mod, :create_calendar_event]

    test "it updates the event when posting valid params", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}", calendar_event: @valid_attrs
      updated_calendar_event = Repo.get(CalendarEvent, calendar_event.id)
      assert updated_calendar_event.title == @valid_attrs.title
      assert updated_calendar_event.description == @valid_attrs.description
      assert updated_calendar_event.user_id == calendar_event.user_id
      assert redirected_to(conn) == calendar_event_path(conn, :show, calendar_event)
    end

    test "it does not update the event and re-renders the edit template when posting invalid params", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}", calendar_event: @invalid_attrs
      assert html_response(conn, 200) =~ gettext("Edit event")
    end
  end

  describe "update/2 when signed in as a user" do
    setup [:create_and_sign_in_user, :create_calendar_event]

    test "it does not update the event and shows a 401 error", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent 403, fn ->
        put conn, "/calendar_events/#{calendar_event.id}", calendar_event: @valid_attrs
      end

      updated_calendar_event = Repo.get(CalendarEvent, calendar_event.id)
      refute updated_calendar_event.title == @valid_attrs.title
    end
  end

  describe "update/2 when not signed in" do
    setup [:create_calendar_event]

    test "it does not update the event and instead redirects to the sign in page", %{conn: conn, calendar_event: calendar_event} do
      conn = put conn, "/calendar_events/#{calendar_event.id}", calendar_event: @valid_attrs
      assert redirected_to(conn) =~ session_path(conn, :new)
      updated_calendar_event = Repo.get(CalendarEvent, calendar_event.id)
      refute updated_calendar_event.title == @valid_attrs.title
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in as an admin" do
    setup [:create_and_sign_in_admin, :create_calendar_event]

    test "it deletes the event and redirects to the list of events", %{conn: conn, calendar_event: calendar_event} do
      conn = delete conn, "/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) == calendar_event_path(conn, :index)
      refute Repo.get(CalendarEvent, calendar_event.id)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        delete conn, "/calendar_events/#{calendar_event.id + 1}"
      end
    end
  end

  describe "delete/2 when signed in as a moderator" do
    setup [:create_and_sign_in_mod, :create_calendar_event]

    test "it deletes the event and redirects to the list of events", %{conn: conn, calendar_event: calendar_event} do
      conn = delete conn, "/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) == calendar_event_path(conn, :index)
      refute Repo.get(CalendarEvent, calendar_event.id)
    end

    test "it shows a 404 error when providing an invalid id", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent :not_found, fn ->
        delete conn, "/calendar_events/#{calendar_event.id + 1}"
      end
    end
  end

  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user, :create_calendar_event]

    test "it does not delete the event but shows a 401 error", %{conn: conn, calendar_event: calendar_event} do
      assert_error_sent 403, fn ->
        delete conn, "/calendar_events/#{calendar_event.id}"
      end
      assert Repo.get(CalendarEvent, calendar_event.id)
    end
  end

  describe "delete/2 when not signed in" do
    setup [:create_calendar_event]

    test "it does not delete the blog post and instead redirects to the sign in page", %{conn: conn, calendar_event: calendar_event} do
      conn = delete conn, "/calendar_events/#{calendar_event.id}"
      assert redirected_to(conn) =~ session_path(conn, :new)
      assert Repo.get(CalendarEvent, calendar_event.id)
    end
  end

  ##############################################################################
  # SETUP
  defp create_calendar_event(_context) do
    calendar_event = insert(:calendar_event)
    {:ok, calendar_event: calendar_event}
  end
end
