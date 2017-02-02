defmodule Helheim.NotificationChannel do
  use Phoenix.Channel
  import Guardian.Phoenix.Socket
  alias Helheim.Repo

  def join("notifications:" <> user_id, %{"guardian_token" => token}, socket) do
    authenticate_channel socket, user_id, token
  end

  def join(_room, _, _socket) do
    {:error, :authentication_required}
  end

  def handle_in("ping", _payload, socket) do
    user = current_resource(socket)
    broadcast(socket, "pong", %{message: "pong", from: user.email})
    {:noreply, socket}
  end

  def broadcast_notification(notification) do
    notification = notification |> Repo.preload(:user)
    payload = %{
      title: notification.title,
      icon: notification.icon,
      path: notification.path
    }
    Helheim.Endpoint.broadcast("notifications:#{notification.user.id}", "notification", payload)
  end

  # Authenticate users to make sure that they are signed in
  defp authenticate_channel(socket, user_id, token) do
    case sign_in(socket, token) do
      {:ok, socket, _guardian_params} ->
        authorize_channel(socket, user_id)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Authorize users to make sure that they can only join their own notification
  # channel
  defp authorize_channel(socket, user_id) do
    if Integer.to_string(current_resource(socket).id) == user_id do
      {:ok, %{message: "Joined"}, socket}
    else
      {:error, :unauthorized_for_this_channel}
    end
  end
end
