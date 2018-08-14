defmodule Helheim.OnlineUsersService do
  alias Helheim.Repo
  alias Helheim.User
  alias HelheimWeb.Presence

  def count, do: user_ids() |> length()

  def list do
    User
    |> User.with_ids(user_ids())
    |> User.sort("username", "asc")
    |> Repo.all()
  end

  ### PRIVATE
  defp user_ids(), do: HelheimWeb.Presence.list("status") |> Map.keys
end
