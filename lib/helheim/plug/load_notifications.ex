defmodule Helheim.Plug.LoadNotifications do
  import Plug.Conn
  alias Helheim.Notification

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    notifications = Notification.list_not_clicked(user)
    conn
    |> assign(:notifications, notifications)
    |> assign(:notifications_count, length(notifications))
  end
end
