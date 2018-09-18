defmodule HelheimWeb.NavbarController do
  use HelheimWeb, :controller

  def show(conn, _params) do
    render conn, "show.html", layout: false
  end
end
