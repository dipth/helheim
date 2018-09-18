defmodule Helheim.OnlineUsersService do
  alias Helheim.Repo
  alias Helheim.User
  alias HelheimWeb.Presence

  def count(current_user_id), do: user_ids(current_user_id) |> length()

  def list(current_user_id) do
    User
    |> User.with_ids(user_ids(current_user_id))
    |> User.sort("last_login_at", "desc")
    |> Repo.all()
  end

  ### PRIVATE
  defp user_ids(current_user_id) do
    Map.merge(%{inspect(current_user_id) => %{}}, Presence.list("status"))
    |> Map.keys
  end
end
