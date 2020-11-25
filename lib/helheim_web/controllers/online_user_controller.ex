defmodule HelheimWeb.OnlineUserController do
  use HelheimWeb, :controller
  alias Helheim.OnlineUsersService

  def index(conn, _params) do
    user = current_resource(conn)
    users = OnlineUsersService.list(user)
    count = length(users)
    render conn, "index.html", count: count, users: users
  end
end
