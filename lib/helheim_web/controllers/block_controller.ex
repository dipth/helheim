defmodule HelheimWeb.BlockController do
  use HelheimWeb, :controller
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

  def show(conn, %{"id" => blocker_id}) do
    blocker = Repo.get!(User, blocker_id)
    blockee = current_resource(conn)
    block   = Block
              |> Block.for_blocker(blocker)
              |> Block.for_blockee(blockee)
              |> Block.enabled()
              |> Repo.one!
    render(conn, "show.html", block: block, blocker: blocker)
  end

  def new(conn, _params) do
    blocker   = current_resource(conn)
    users     = User
                |> User.blockable_by(blocker)
                |> User.sort("username", "asc")
                |> Repo.all
    render(conn, "new.html", users: users)
  end

  def create(conn, %{"blockee_id" => blockee_id}) do
    with blocker <- current_resource(conn),
      {:ok, blockee} <- find_blockee(blocker, blockee_id),
      {:ok, _block} <- Block.block!(blocker, blockee)
    do
      conn
      |> put_flash(:success, gettext("User successfully blocked!"))
      |> redirect(to: block_and_ignore_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, gettext("Unable to block user!"))
        |> redirect(to: block_and_ignore_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => blockee_id}) do
    blocker = current_resource(conn)
    blockee = Repo.get!(User, blockee_id)

    case Block.unblock!(blocker, blockee) do
      {:ok, _block} ->
        conn
        |> put_flash(:success, gettext("User unblocked!"))
        |> redirect(to: block_and_ignore_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Unable to unblock user!"))
        |> redirect(to: block_and_ignore_path(conn, :index))
    end
  end

  defp find_blockee(blocker, blockee_id) do
    blockee = User |> User.blockable_by(blocker) |> Repo.get(blockee_id)
    if blockee do
      {:ok, blockee}
    else
      {:error, :blockee_not_found}
    end
  end
end
