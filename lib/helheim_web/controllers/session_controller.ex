defmodule HelheimWeb.SessionController do
  use HelheimWeb, :controller

  plug :put_layout, "app_special.html"

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password, "remember_me" => remember_me}}) do
    case HelheimWeb.Auth.login_by_email_and_pass(conn, email, password) do
      {:ok, conn} ->
        user = Guardian.Plug.current_resource(conn)
        conn
        |> set_remember_me(user, remember_me)
        |> put_flash(:success, gettext("Welcome back %{username}!", username: user.username))
        |> redirect(to: page_path(conn, :front_page))
      {:error, :unconfirmed, conn} ->
        conn
        |> put_flash(:warning, gettext("You need to confirm your e-mail address before you can log in"))
        |> render("new.html")
      {:error, _reason, conn} ->
        conn
        |> put_flash(:warning, gettext("Wrong e-mail or password"))
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Guardian.Plug.sign_out
    |> put_resp_cookie("remember_me", "", max_age: 1)
    |> put_flash(:success, gettext("See you later!"))
    |> redirect(to: page_path(conn, :index))
  end

  defp set_remember_me(conn, user, remember_me) do
    case remember_me do
      "true" ->
        {:ok, jwt, _claims} = Guardian.encode_and_sign(user, "refresh")
        thirty_days = 30*24*60*60
        conn
        |> put_resp_cookie("remember_me", jwt, max_age: thirty_days, secure: Mix.env == :prod)
      _ ->
        conn
    end
  end
end
