defmodule HelheimWeb.UsernameController do
  use HelheimWeb, :controller
  alias Helheim.Repo
  alias Helheim.User

  def index(conn, _) do
    usernames = User |> order_by(asc: :username) |> select([:id, :username]) |> Repo.all
    render(conn, "index.json", usernames: usernames)
  end

  def show(conn, %{"id" => username}) do
    user = Repo.get_by!(User, username: username)
    redirect(conn, to: public_profile_path(conn, :show, user))
  end
end
