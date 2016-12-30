defmodule Altnation.PageController do
  use Altnation.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
