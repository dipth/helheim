defmodule Helheim.UsernameController do
  use Helheim.Web, :controller
  alias Helheim.Repo
  alias Helheim.User

  def show(conn, %{"id" => username}) do
    user = Repo.get_by!(User, username: username)
    redirect(conn, to: public_profile_path(conn, :show, user))
  end
end
