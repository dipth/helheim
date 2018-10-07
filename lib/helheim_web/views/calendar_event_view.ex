defmodule HelheimWeb.CalendarEventView do
  use HelheimWeb, :view

  def calendar_event_month(calendar_event) do
    {:ok, string} = Timex.lformat(calendar_event.starts_at, "%b", "da", :strftime)
    String.capitalize(string)
  end

  def calendar_event_day(calendar_event) do
    {:ok, string} = Timex.lformat(calendar_event.starts_at, "%e", "da", :strftime)
    string
  end

  def calendar_event_timespan(calendar_event) do
    {:ok, starts_at} = calendar_event_timestamp(calendar_event.starts_at)
    {:ok, ends_at} = calendar_event_timestamp(calendar_event.ends_at)
    "#{starts_at} - #{ends_at}"
  end

  def calendar_event_timestamp(timestamp) do
    now = Timex.now("Europe/Copenhagen")
    cond do
      now.year == timestamp.year ->
        Timex.lformat(timestamp, "%d. %B, kl. %H:%M", "da", :strftime)
      true ->
        Timex.lformat(timestamp, "%d. %B %Y, kl. %H:%M", "da", :strftime)
    end
  end
end
