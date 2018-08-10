defmodule Helheim.HelpController do
  use Helheim.Web, :controller
  alias Helheim.User

  def verification(conn, _params) do
    user = current_resource(conn)
    verified = User.verified?(user)
    render conn, "verification.html", verified: verified
  end
end
