defmodule HelheimWeb.Plug.LoadPendingCalendarEvents do
  import Plug.Conn
  alias Helheim.CalendarEvent

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    assign_count(conn, Guardian.Plug.current_resource(conn))
  end

  defp assign_count(conn, %{role: "admin"}) do
    count = CalendarEvent.pending_count()
    assign(conn, :pending_calendar_events_count, count)
  end
  defp assign_count(conn, _), do: conn
end
