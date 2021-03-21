defmodule HelheimWeb.Plug.LoadIgnorees do
  import Plug.Conn
  alias Helheim.Ignore
  alias Helheim.Repo

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)
    ids  = Ignore |> Ignore.for_ignorer(user) |> Ignore.enabled() |> Repo.all() |> Enum.map(&(&1.ignoree_id))
    assign(conn, :ignoree_ids, ids)
  end
end
