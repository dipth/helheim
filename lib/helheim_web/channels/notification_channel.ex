defmodule HelheimWeb.NotificationChannel do
  use Phoenix.Channel
  import Guardian.Phoenix.Socket

  def join("notifications:" <> user_id, %{}, socket) do
    authorize_channel socket, user_id
  end

  def join(_room, _, _socket) do
    {:error, :authentication_required}
  end

  def handle_in("ping", _payload, socket) do
    user = current_resource(socket)
    broadcast(socket, "pong", %{message: "pong", from: user.email})
    {:noreply, socket}
  end

  def broadcast_notification(recipient_id) do
    HelheimWeb.Endpoint.broadcast("notifications:#{recipient_id}", "notification", %{})
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
