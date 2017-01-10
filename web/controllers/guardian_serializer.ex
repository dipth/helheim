defmodule Altnation.GuardianSerializer do
  @behaviour Guardian.Serializer
  import Altnation.Gettext
  alias Altnation.Repo
  alias Altnation.User
  def for_token(user = %User{}), do: {:ok, "User:#{user.id}"}
  def for_token(_), do: {:error, gettext("Unknown resource type")}
  def from_token("User:" <> id), do: {:ok, Repo.get(User, id)}
  def from_token(_), do: {:error, gettext("Unknown resource type")}
end
