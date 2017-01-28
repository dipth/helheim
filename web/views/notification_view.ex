defmodule Helheim.NotificationView do
  use Helheim.Web, :view
  alias Helheim.Repo
  alias Helheim.Notification

  def unread_notifications(conn) do
    user = Guardian.Plug.current_resource(conn)
    Ecto.assoc(user, :notifications)
    |> Notification.unread
    |> Notification.newest
    |> Repo.all
  end
end
