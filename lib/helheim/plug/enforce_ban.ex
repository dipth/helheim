defmodule HelheimWeb.Plug.EnforceBan do
  import Plug.Conn
  alias Helheim.User

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if User.banned?(user) && conn.request_path != "/banned" do
      conn
      |> Phoenix.Controller.redirect(to: "/banned")
      |> halt
    else
      conn
    end
  end
end
