defmodule HelheimWeb.SessionController do
  use HelheimWeb, :controller

  alias Helheim.Auth
  alias Helheim.Auth.Guardian

  plug :put_layout, "app_special.html"

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password, "remember_me" => remember_me}}) do
    remote_ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    Auth.authenticate_user(email, password, remote_ip)
    |> login_reply(conn, remember_me)
  end

  def delete(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> delete_resp_cookie("guardian_default_token")
    |> put_flash(:success, gettext("See you later!"))
    |> redirect(to: page_path(conn, :index))
  end

  defp login_reply({:error, error}, conn, _) do
    conn
    |> put_flash(:warning, translate_error(error))
    |> render("new.html")
  end
  defp login_reply({:ok, user}, conn, remember_me) do
    conn
    |> put_flash(:success, gettext("Welcome back %{username}!", username: user.username))
    |> Guardian.Plug.sign_in(user)
    |> maybe_remember_me(remember_me, user)
    |> redirect(to: page_path(conn, :front_page))
  end

  defp maybe_remember_me(conn, "true", user), do: Guardian.Plug.remember_me(conn, user)
  defp maybe_remember_me(conn, _, _), do: conn

  defp translate_error(:not_found), do: gettext("Wrong e-mail or password")
  defp translate_error(:unconfirmed), do: gettext("You need to confirm your e-mail address before you can log in")
  defp translate_error(:unauthorized), do: gettext("Wrong e-mail or password")
  defp translate_error(error), do: error
end
