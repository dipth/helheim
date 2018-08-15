defmodule Helheim.PreferenceController do
  use Helheim.Web, :controller
  alias Helheim.User

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.preferences_changeset(user)
    render conn, "edit.html", changeset: changeset
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.preferences_changeset(user, user_params)
    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, gettext("Preferences updated!"))
        |> redirect(to: page_path(conn, :front_page))
      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end
end
