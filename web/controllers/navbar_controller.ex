defmodule Helheim.NavbarController do
  use Helheim.Web, :controller

  def show(conn, _params) do
    render conn, "show.html", layout: false
  end
end
