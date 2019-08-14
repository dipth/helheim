defmodule Helheim.CalendarEventService do
  alias Helheim.CalendarEvent
  alias Helheim.NotificationSubscription
  alias Helheim.Repo

  def create!(author, params) do
    with {:ok, event} <- create_calendar_event(author, params),
         {:ok, _sub} <- create_notification_subscription(author, event)
    do
      {:ok, event}
    end
  end

  defp create_calendar_event(author, params) do
    author
    |> Ecto.build_assoc(:calendar_events)
    |> CalendarEvent.changeset(params)
    |> Repo.insert()
  end

  defp create_notification_subscription(author, event) do
    NotificationSubscription.enable!(author, "comment", event)
  end
end
