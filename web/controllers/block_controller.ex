defmodule Helheim.BlockController do
  use Helheim.Web, :controller
  alias Helheim.Block
  alias Helheim.User

  def index(conn, params) do
    user   = current_resource(conn)
    blocks = Block
             |> Block.for_blocker(user)
             |> Block.enabled()
             |> Block.order_by_blockee_username()
             |> preload(:blockee)
             |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", blocks: blocks)
  end

  def show(conn, %{"profile_id" => profile_id}) do
    blocker = Repo.get!(User, profile_id)
    block   = Block
              |> Block.for_blocker(blocker)
              |> Block.for_blockee(current_resource(conn))
              |> Block.enabled()
              |> Repo.one!
    render(conn, "show.html", block: block, blocker: blocker)
  end

  def create(conn, %{"profile_id" => profile_id}) do
    blockee = Repo.get!(User, profile_id)
    case Block.block!(current_resource(conn), blockee) do
      {:ok, _block} ->
        conn
        |> put_flash(:success, gettext("User blocked!"))
        |> redirect(to: block_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Unable to block user!"))
        |> redirect(to: block_path(conn, :index))
    end
  end

  def delete(conn, %{"profile_id" => profile_id}) do
    blockee = Repo.get!(User, profile_id)
    case Block.unblock!(current_resource(conn), blockee) do
      {:ok, _block} ->
        conn
        |> put_flash(:success, gettext("User unblocked!"))
        |> redirect(to: block_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Unable to unblock user!"))
        |> redirect(to: block_path(conn, :index))
    end
  end
end
