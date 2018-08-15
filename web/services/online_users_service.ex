defmodule Helheim.OnlineUsersService do
  alias Helheim.Repo
  alias Helheim.User
  alias HelheimWeb.Presence

  def count(current_user_id), do: user_ids(current_user_id) |> length()

  def list(current_user_id) do
    User
    |> User.with_ids(user_ids(current_user_id))
    |> User.sort("inserted_at", "asc")
    |> Repo.all()
  end

  ### PRIVATE
  defp user_ids(current_user_id) do
    ids =
      Presence.list("status")
      |> Map.drop(["747"])

    Map.merge(%{inspect(current_user_id) => %{}}, ids)
    |> Map.keys
  end
end
