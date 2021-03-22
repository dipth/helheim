defmodule HelheimWeb.IgnoreController do
  use HelheimWeb, :controller
  alias Helheim.Ignore
  alias Helheim.User

  def new(conn, _params) do
    ignorer   = current_resource(conn)
    users     = User
                |> User.ignorable_by(ignorer)
                |> User.sort("username", "asc")
                |> Repo.all
    render(conn, "new.html", users: users)
  end

  def create(conn, %{"ignoree_id" => ignoree_id}) do
    with ignorer <- current_resource(conn),
      {:ok, ignoree} <- find_ignoree(ignorer, ignoree_id),
      {:ok, _block} <- Ignore.ignore!(ignorer, ignoree)
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

  def delete(conn, %{"id" => ignoree_id}) do
    ignorer = current_resource(conn)
    ignoree = Repo.get!(User, ignoree_id)

    case Ignore.unignore!(ignorer, ignoree) do
      {:ok, _block} ->
        conn
        |> put_flash(:success, gettext("User unignored!"))
        |> redirect(to: block_and_ignore_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Unable to unignore user!"))
        |> redirect(to: block_and_ignore_path(conn, :index))
    end
  end

  defp find_ignoree(ignorer, ignoree_id) do
    ignoree = User |> User.ignorable_by(ignorer) |> Repo.get(ignoree_id)
    if ignoree do
      {:ok, ignoree}
    else
      {:error, :ignoree_not_found}
    end
  end
end
