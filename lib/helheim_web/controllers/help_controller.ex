defmodule HelheimWeb.HelpController do
  use HelheimWeb, :controller
  alias Helheim.User

  def verification(conn, _params) do
    user = current_resource(conn)
    verified = User.verified?(user)
    render conn, "verification.html", verified: verified
  end
end
