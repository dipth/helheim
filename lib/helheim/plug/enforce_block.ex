defmodule Helheim.Plug.EnforceBlock do
  import Plug.Conn
  import Guardian.Plug, only: [current_resource: 1]
  import Helheim.Router.Helpers
  alias Helheim.Block

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    blocker = conn.assigns[:user]
    blockee = current_resource(conn)

    cond do
      blocker != nil && Block.blocked?(blocker, blockee) ->
        conn
        |> Phoenix.Controller.redirect(to: public_profile_block_path(conn, :show, blocker))
        |> halt
      true -> conn
    end
  end
end
