defmodule Altnation.SessionController do
  use Altnation.Web, :controller

  plug :put_layout, "app_special.html"

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Altnation.Auth.login_by_email_and_pass(conn, email, password) do
      {:ok, conn} ->
        user = Guardian.Plug.current_resource(conn)
        conn
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
    |> put_flash(:success, gettext("See you later!"))
    |> redirect(to: page_path(conn, :index))
  end
end
