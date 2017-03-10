defmodule Helheim.HelpController do
  use Helheim.Web, :controller

  def embeds(conn, _params) do
    render conn, "embeds.html"
  end
end
