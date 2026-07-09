defmodule HelheimWeb.PreferenceController do
  use HelheimWeb, :controller
  alias Helheim.User

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.preferences_changeset(user)
    spotify_account = Repo.get_by(Helheim.SpotifyAccount, user_id: user.id)
    render conn, "edit.html", changeset: changeset, spotify_account: spotify_account
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
        spotify_account = Repo.get_by(Helheim.SpotifyAccount, user_id: user.id)
        conn
        |> render("edit.html", changeset: changeset, spotify_account: spotify_account)
    end
  end
end
