defmodule Helheim.UserSocket do
  use Phoenix.Socket
  import Guardian.Phoenix.Socket

  ## Channels
  channel "notifications:*", Helheim.NotificationChannel
  channel "status", Helheim.StatusChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket, timeout: 45_000
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"guardian_token" => jwt}, socket) do
    case sign_in(socket, jwt) do
      {:ok, authed_socket, _guardian_params} ->
        {:ok, authed_socket}
      _ ->
        {:error, :unauthorized}
    end
  end

  def connect(_params, _socket) do
    {:error, :unauthorized}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Helheim.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` will make this socket anonymous.
  def id(socket) do
    user = current_resource(socket)
    if user do
      "users_socket:#{user.id}"
    else
      nil
    end
  end
end
