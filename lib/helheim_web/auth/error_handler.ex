defmodule HelheimWeb.Auth.ErrorHandler do
  import Phoenix.Controller
  import HelheimWeb.Router.Helpers
  import HelheimWeb.Gettext

  def auth_error(conn, {type, reason}, _opts) do
    conn
    |> put_flash(:warning, gettext("You need to be signed in to access the requested page!"))
    |> redirect(to: session_path(conn, :new, type: to_string(type), reason: to_string(reason)))
  end
end
