defmodule HelheimWeb.Plug.VerifyMod do
  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    case user.role do
      "admin" ->
        conn
      "mod" ->
        conn
      _ ->
        raise HelheimWeb.Forbidden, message: "Only for admins!"
    end
  end
end
