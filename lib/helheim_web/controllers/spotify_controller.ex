defmodule HelheimWeb.SpotifyController do
  use HelheimWeb, :controller
  alias Helheim.User

  def authorize(conn, params) do
    redirect conn, external: Spotify.Authorization.url
  end

  def callback(conn, params) do
    with  {:ok, conn} <- Spotify.Authentication.authenticate(conn, params),
          {:ok, _changeset} <- store_tokens(conn) do
            conn
            |> put_flash(:success, gettext("You have successfully connected your Spotify account."))
            |> redirect(to: page_path(conn, :front_page))
          else
            _ ->
              conn
              |> put_flash(:error, gettext("We were unable to connect your Spotify account."))
              |> redirect(to: page_path(conn, :front_page))
          end
  end

  defp store_tokens(conn) do
    user          = current_resource(conn)
    access_token  = Spotify.Cookies.get_access_token(conn)
    refresh_token = Spotify.Cookies.get_refresh_token(conn)
    changeset     = Ecto.Changeset.change(user, %{spotify_access_token: access_token, spotify_refresh_token: refresh_token})

    Repo.update(changeset)
  end
end
