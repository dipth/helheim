defmodule Helheim.Plug.VerifyAdmin do
  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    case user.role do
      "admin" ->
        conn
      _ ->
        raise Helheim.Forbidden, message: "Only for admins!"
    end
  end
end
