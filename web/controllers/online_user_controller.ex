defmodule Helheim.OnlineUserController do
  use Helheim.Web, :controller
  alias Helheim.OnlineUsersService

  def index(conn, _params) do
    render conn, "index.html", count: OnlineUsersService.count(), users: OnlineUsersService.list()
  end
end
