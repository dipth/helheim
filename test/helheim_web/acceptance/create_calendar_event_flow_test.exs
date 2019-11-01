defmodule HelheimWeb.CreateCalendarEventFlowTest do
  use HelheimWeb.AcceptanceCase
  alias Helheim.CalendarEvent
  alias Helheim.Repo

  defp calendar_events_link,  do: Query.link(gettext("Event calendar"))
  defp create_link,           do: Query.link(gettext("Create event"))
  defp title_field,           do: Query.text_field(gettext("Title"))
  defp description_field,     do: Query.text_field(gettext("Give a good description of the event"))
  defp starts_at_flatpickr,   do: Query.css("div.form-group.starts-at .flatpickr-calendar")
  defp starts_at_day,         do: Query.css("div.form-group.starts-at .flatpickr-day", text: "15")
  defp starts_at_hour,        do: Query.css("div.form-group.starts-at input.flatpickr-hour")
  defp starts_at_minute,      do: Query.css("div.form-group.starts-at input.flatpickr-minute")
  defp ends_at_flatpickr,     do: Query.css("div.form-group.ends-at .flatpickr-calendar")
  defp ends_at_day,           do: Query.css("div.form-group.ends-at .flatpickr-day", text: "16")
  defp ends_at_hour,          do: Query.css("div.form-group.ends-at input.flatpickr-hour")
  defp ends_at_minute,        do: Query.css("div.form-group.ends-at input.flatpickr-minute")
  defp location_field,        do: Query.text_field(gettext("Where does the event take place?"))
  defp url_field,             do: Query.text_field(gettext("Specify a website where there is more information about the event, if available"))
  defp submit_button,         do: Query.button(gettext("Save"))
  defp success_alert,         do: Query.css(".alert.alert-success")

  setup [:create_and_sign_in_user]

  test "users can submit new calendar events", %{session: session} do
    result =
      session
      |> click(calendar_events_link())
      |> click(create_link())
      |> fill_in(title_field(), with: "Super duper event!")
      |> fill_in(description_field(), with: "This is a super duper test event.")
      |> assert_has(starts_at_flatpickr())
      |> click(starts_at_day())
      |> assert_has(starts_at_hour())
      |> fill_in(starts_at_hour(), with: "16")
      |> assert_has(starts_at_minute())
      |> fill_in(starts_at_minute(), with: "25")
      |> assert_has(ends_at_flatpickr())
      |> click(ends_at_day())
      |> assert_has(ends_at_hour())
      |> fill_in(ends_at_hour(), with: "18")
      |> assert_has(ends_at_minute())
      |> fill_in(ends_at_minute(), with: "45")
      |> fill_in(location_field(), with: "A super secret location")
      |> fill_in(url_field(), with: "https://super.duper/event")
      |> click(submit_button())
      |> find(success_alert())
      |> Element.text

    assert result =~ gettext("The event has now been created and will be shown on the site when it has been approved by an administrator.")

    now = Timex.now
    calendar_event = Repo.one!(CalendarEvent)
    assert calendar_event.title == "Super duper event!"
    assert calendar_event.description == "This is a super duper test event."
    assert Timex.diff(calendar_event.starts_at, NaiveDateTime.new(now.year, now.month, 15, 16, 25, 0, 0) |> elem(1), :seconds) == 0
    assert Timex.diff(calendar_event.ends_at, NaiveDateTime.new(now.year, now.month, 16, 18, 45, 0, 0) |> elem(1), :seconds) == 0
    assert calendar_event.location == "A super secret location"
    assert calendar_event.url == "https://super.duper/event"
    assert CalendarEvent.pending?(calendar_event)
  end
end
