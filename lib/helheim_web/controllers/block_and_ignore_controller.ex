defmodule HelheimWeb.BlockAndIgnoreController do
  use HelheimWeb, :controller
  alias Helheim.Block
  alias Helheim.Ignore
  alias Helheim.User

  def index(conn, _params) do
    user    = current_resource(conn)
    blocks  = find_blocks(user)
    ignores = find_ignores(user)
    render(conn, "index.html", blocks: blocks, ignores: ignores)
  end

  defp find_blocks(user) do
    Block
    |> Block.for_blocker(user)
    |> Block.enabled()
    |> Block.order_by_blockee_username()
    |> preload(:blockee)
    |> Repo.all
  end

  defp find_ignores(user) do
    Ignore
    |> Ignore.for_ignorer(user)
    |> Ignore.enabled()
    |> Ignore.order_by_ignoree_username()
    |> preload(:ignoree)
    |> Repo.all
  end
end
