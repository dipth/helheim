defmodule HelheimWeb.StatusChannel do
  use Phoenix.Channel
  alias HelheimWeb.Presence
  import Guardian.Phoenix.Socket

  def join("status", %{}, socket) do
    authorize_channel(socket)
  end

  def join(_room, _, _socket) do
    {:error, :authentication_required}
  end

  def handle_info(:after_join, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, current_resource(socket).id, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  # Authorize users to make sure that they can only join their own notification
  # channel
  defp authorize_channel(socket) do
    send(self(), :after_join)
    {:ok, socket}
  end
end
