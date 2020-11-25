defmodule Helheim.OnlineUsersService do
  alias Helheim.Repo
  alias Helheim.User
  alias HelheimWeb.Presence

  def count(current_user), do: user_ids(current_user) |> length()

  def list(current_user) do
    User
    |> User.with_ids(user_ids(current_user))
    |> User.sort("last_login_at", "desc")
    |> Repo.all()
  end

  ### PRIVATE
  defp user_ids(%{id: current_user_id, incognito: current_user_incognito}) do
    all = Map.merge(%{inspect(current_user_id) => %{metas: [%{incognito: current_user_incognito}]}}, Presence.list("status"))
    excluding_incognito = :maps.filter fn _, v -> !is_incognito?(v) end, all

    excluding_incognito
    |> Map.keys
  end

  defp is_incognito?(%{metas: [%{incognito: incognito}]}), do: incognito
  defp is_incognito?(_), do: false
end
