defmodule HelheimWeb.Token do
  use HelheimWeb, :controller

  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:info, gettext("You must be signed in to access this page"))
    |> redirect(to: session_path(conn, :new))
  end

  def unauthorized(conn, _params) do
    conn
    |> put_flash(:error, gettext("You must be signed in to access this page"))
    |> redirect(to: session_path(conn, :new))
  end
end
