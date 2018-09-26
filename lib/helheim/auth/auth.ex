defmodule Helheim.Auth do
  @moduledoc """
  The Auth context.
  """

  import Ecto.Query, warn: false
  alias Helheim.Repo

  alias Helheim.User
  alias Comeonin.Bcrypt

  @doc """
  Searches the database for a user with the matching username, then
  checks that encrypting the plain text password matches in the
  encrypted password that was stored during user creation.
  """
  def authenticate_user(email, password, remote_ip) do
    with {:ok, user} <- load_user(email),
         {:ok} <- check_password(user, password),
         {:ok} <- check_confirmation(user),
         {:ok, user} <- User.track_login!(user, remote_ip)
    do
      {:ok, user}
    end
  end

  defp load_user(nil), do: {:error, :not_found}
  defp load_user(email) do
    email = String.trim(email)
    query = from u in User, where: u.email == ^email
    user = Repo.one(query)
    case user do
      nil -> {:error, :not_found}
      _ -> {:ok, user}
    end
  end

  defp check_password(user, password) do
    case password_correct?(password, user) do
      true -> {:ok}
      false -> {:error, :unauthorized}
    end
  end

  defp check_confirmation(user) do
    case User.confirmed?(user) do
      true -> {:ok}
      false -> {:error, :unconfirmed}
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def password_correct?(_, nil), do: Bcrypt.dummy_checkpw()
  def password_correct?(password, %User{} = user), do: password_correct?(password, user.password_hash)
  def password_correct?(password, encrypted_password), do: Bcrypt.checkpw(password, encrypted_password)
end
