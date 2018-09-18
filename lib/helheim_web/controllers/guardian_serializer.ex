defmodule HelheimWeb.GuardianSerializer do
  @behaviour Guardian.Serializer
  import HelheimWeb.Gettext
  alias Helheim.Repo
  alias Helheim.User
  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, gettext("Unknown resource type")}
  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, gettext("Unknown resource type")}
end
