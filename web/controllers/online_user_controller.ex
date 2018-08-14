defmodule Helheim.OnlineUserController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.Repo

  def index(conn, _params) do
    render conn, "index.html", users: online_users()
  end

  defp online_users do
    ids = HelheimWeb.Presence.list("status") |> Map.keys
    User |> User.with_ids(ids) |> User.sort("username", "asc") |> Repo.all()
  end
end
