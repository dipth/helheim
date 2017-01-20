defmodule Altnation.ProfileController do
  use Altnation.Web, :controller
  alias Altnation.User

  def show(conn, params) do
    user = if params["id"] do
      Repo.get(User, params["id"])
    else
      Guardian.Plug.current_resource(conn)
    end

    if user do
      render conn, "show.html", user: user
    else
      conn
      |> put_flash(:error, gettext("The requested profile could not be found!"))
      |> redirect(to: page_path(conn, :front_page))
    end
  end

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.profile_changeset(user)
    render conn, "edit.html", changeset: changeset
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.profile_changeset(user, user_params)
    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, gettext("Profile updated!"))
        |> redirect(to: page_path(conn, :front_page))
      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end
end
