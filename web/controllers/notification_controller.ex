defmodule Helheim.NotificationController do
  use Helheim.Web, :controller
  alias Helheim.Notification

  def show(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    {:ok, notification} =
      assoc(user, :notifications)
      |> Repo.get!(id)
      |> Notification.mark_as_read!
    redirect(conn, to: notification.path)
  end

  def refresh(conn, _params) do
    conn
    |> put_layout(false)
    |> render("refresh.html")
  end
end
