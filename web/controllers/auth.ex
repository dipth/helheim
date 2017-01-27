require IEx;

defmodule Helheim.Auth do
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Helheim.Repo
  alias Helheim.User

  def login(conn, user) do
    conn
    |> Guardian.Plug.sign_in(user, :access)
  end

  def login_by_email_and_pass(conn, email, given_pass) do
    user = Repo.get_by(User, email: String.trim(email))

    cond do
      user && User.confirmed?(user) && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user && checkpw(given_pass, user.password_hash) ->
        {:error, :unconfirmed, conn}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def password_correct?(password_hash, given_pass) do
    checkpw(given_pass, password_hash)
  end
end
