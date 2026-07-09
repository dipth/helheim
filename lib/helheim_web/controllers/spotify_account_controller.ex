defmodule HelheimWeb.SpotifyAccountController do
  use HelheimWeb, :controller
  alias Helheim.Spotify.Client
  alias Helheim.SpotifyAccountService

  def create(conn, _params) do
    state = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    conn
    |> put_session(:spotify_oauth_state, state)
    |> redirect(external: Client.authorize_url(state))
  end

  def callback(conn, %{"error" => _error}) do
    conn
    |> put_flash(:warning, gettext("The Spotify connection was cancelled."))
    |> redirect(to: preference_path(conn, :edit))
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    user = current_resource(conn)
    expected_state = get_session(conn, :spotify_oauth_state)
    conn = delete_session(conn, :spotify_oauth_state)

    with true <- !is_nil(expected_state) && Plug.Crypto.secure_compare(state, expected_state),
         {:ok, token_data} <- Client.exchange_code(code),
         {:ok, _account} <- SpotifyAccountService.connect!(user, token_data) do
      conn
      |> put_flash(:success, gettext("Your Spotify account is now connected!"))
      |> redirect(to: preference_path(conn, :edit))
    else
      _ ->
        conn
        |> put_flash(:error, gettext("Your Spotify account could not be connected. Please try again."))
        |> redirect(to: preference_path(conn, :edit))
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, gettext("Your Spotify account could not be connected. Please try again."))
    |> redirect(to: preference_path(conn, :edit))
  end

  def delete(conn, _params) do
    {:ok, _} = SpotifyAccountService.disconnect!(current_resource(conn))

    conn
    |> put_flash(:success, gettext("Your Spotify account has been disconnected."))
    |> redirect(to: preference_path(conn, :edit))
  end

  def delete_history(conn, _params) do
    {:ok, _} = SpotifyAccountService.delete_history!(current_resource(conn))

    conn
    |> put_flash(:success, gettext("Your listening history has been deleted."))
    |> redirect(to: preference_path(conn, :edit))
  end
end
