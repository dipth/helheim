defmodule HelheimWeb.CalendarEventController do
  use HelheimWeb, :controller
  alias Helheim.CalendarEvent
  alias Helheim.Comment

  plug HelheimWeb.Plug.VerifyAdmin when action in [:edit, :update, :delete]

  def index(conn, params) do
    calendar_events = calendar_events(params["page"])
    grouped_calendar_events = grouped_calendar_events(calendar_events)
    months = calendar_event_months(grouped_calendar_events)

    render(conn, "index.html", calendar_events: calendar_events, grouped_calendar_events: grouped_calendar_events, months: months)
  end

  def show(conn, %{"id" => id} = params) do
    calendar_event = CalendarEvent |> CalendarEvent.approved() |> Repo.get!(id)
    comments =
      assoc(calendar_event, :comments)
      |> Comment.not_deleted
      |> Comment.newest
      |> Comment.with_preloads
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "show.html", calendar_event: calendar_event, comments: comments)
  end

  def new(conn, _params) do
    changeset = CalendarEvent.changeset(%CalendarEvent{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"calendar_event" => calendar_event_params}) do
    user = current_resource(conn)
    changeset =
      user
      |> Ecto.build_assoc(:calendar_events)
      |> CalendarEvent.changeset(calendar_event_params)

    case Repo.insert(changeset) do
      {:ok, _calendar_event} ->
        conn
        |> put_flash(:success, gettext("The event has now been created and will be shown on the site when it has been approved by an administrator."))
        |> redirect(to: calendar_event_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    calendar_event = Repo.get!(CalendarEvent, id)
    changeset = CalendarEvent.changeset(calendar_event)
    render(conn, "edit.html", changeset: changeset, calendar_event: calendar_event)
  end

  def update(conn, %{"id" => id, "calendar_event" => calendar_event_params}) do
    calendar_event = Repo.get!(CalendarEvent, id)
    changeset = CalendarEvent.changeset(calendar_event, calendar_event_params)
    case Repo.update(changeset) do
      {:ok, calendar_event} ->
        conn
        |> put_flash(:success, gettext("The event was updated successfully."))
        |> redirect(to: calendar_event_path(conn, :show, calendar_event))
      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, calendar_event: calendar_event)
    end
  end

  def delete(conn, %{"id" => id}) do
    calendar_event = Repo.get!(CalendarEvent, id)
    Repo.delete!(calendar_event)
    conn
    |> put_flash(:success, gettext("Event deleted successfully."))
    |> redirect(to: calendar_event_path(conn, :index))
  end

  ### PRIVATE

  defp calendar_events(page) do
    CalendarEvent
    |> CalendarEvent.approved()
    |> CalendarEvent.upcoming()
    |> CalendarEvent.chronological()
    |> Repo.paginate(page: sanitized_page(page))
  end

  defp grouped_calendar_events(calendar_events) do
    calendar_events
    |> Enum.group_by(&calendar_event_month(&1))
  end

  defp calendar_event_month(calendar_event) do
    {:ok, string} = Timex.lformat(calendar_event.starts_at, "%B %Y", "da", :strftime)
    {calendar_event.starts_at.year, calendar_event.starts_at.month, string}
  end

  defp calendar_event_months(grouped_calendar_events) do
    grouped_calendar_events
    |> Map.keys
    |> Enum.sort_by(fn {year, month, _string} -> year + month end)
  end
end
