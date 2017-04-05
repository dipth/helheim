defmodule Helheim.Plug.LoadNotifications do
  import Plug.Conn
  alias Helheim.{Repo, Notification}

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    notifications = Ecto.assoc(user, :notifications)
                    |> Notification.not_clicked
                    |> Notification.newest
                    |> Notification.with_preloads
                    |> Repo.paginate(page: 1, page_size: 10)
    conn
    |> assign(:notifications, notifications.entries)
    |> assign(:notifications_count, notifications.total_entries)
  end
end
