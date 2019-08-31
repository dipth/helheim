defmodule HelheimWeb.Mod.CalendarEventController do
  use HelheimWeb, :controller
  alias Helheim.CalendarEvent
  alias Helheim.Comment

  def index(conn, params) do
    calendar_events =
      CalendarEvent
      |> CalendarEvent.pending()
      |> CalendarEvent.chronological()
      |> preload(:user)
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", calendar_events: calendar_events)
  end

  def show(conn, %{"id" => id} = params) do
    calendar_event = Repo.get!(CalendarEvent, id)
    comments =
      assoc(calendar_event, :comments)
      |> Comment.not_deleted
      |> Comment.newest
      |> Comment.with_preloads
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "show.html", calendar_event: calendar_event, comments: comments)
  end

  def update(conn, %{"id" => id}) do
    calendar_event = Repo.get!(CalendarEvent, id)
    case CalendarEvent.approve!(calendar_event) do
      {:ok, _calendar_event} ->
        conn
        |> put_flash(:success, gettext("The event is now approved."))
        |> redirect(to: mod_calendar_event_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("The event could not be approved!"))
        |> redirect(to: mod_calendar_event_path(conn, :show, calendar_event))
    end
  end

  def delete(conn, %{"id" => id}) do
    calendar_event = Repo.get!(CalendarEvent, id)
    case CalendarEvent.reject!(calendar_event) do
      {:ok, _calendar_event} ->
        conn
        |> put_flash(:success, gettext("The event is now rejected."))
        |> redirect(to: mod_calendar_event_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("The event could not be rejected!"))
        |> redirect(to: mod_calendar_event_path(conn, :show, calendar_event))
    end
  end
end
