defmodule HelheimWeb.LastfmAccountController do
  use HelheimWeb, :controller
  alias Helheim.Lastfm.Client
  alias Helheim.LastfmAccountService

  def create(conn, _params) do
    conn
    |> put_session(:lastfm_connect_pending, true)
    |> redirect(external: Client.auth_url(callback_url(conn)))
  end

  # The callback must return to the host the user is actually browsing on
  # (www vs apex domain, dev hosts), since the session cookie holding the
  # login and the pending flag is scoped to that host.
  defp callback_url(conn) do
    uri = %{HelheimWeb.Endpoint.struct_url() | host: conn.host}
    lastfm_account_url(uri, :callback)
  end

  def callback(conn, %{"token" => token}) do
    user = current_resource(conn)
    pending = get_session(conn, :lastfm_connect_pending)
    conn = delete_session(conn, :lastfm_connect_pending)

    with true <- pending == true,
         {:ok, session} <- Client.get_session(token),
         {:ok, _account} <- LastfmAccountService.connect!(user, session) do
      conn
      |> put_flash(:success, gettext("Your Last.fm account is now connected!"))
      |> redirect(to: preference_path(conn, :edit))
    else
      _ ->
        conn
        |> put_flash(:error, gettext("Your Last.fm account could not be connected. Please try again."))
        |> redirect(to: preference_path(conn, :edit))
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, gettext("Your Last.fm account could not be connected. Please try again."))
    |> redirect(to: preference_path(conn, :edit))
  end

  def delete(conn, _params) do
    {:ok, _} = LastfmAccountService.disconnect!(current_resource(conn))

    conn
    |> put_flash(:success, gettext("Your Last.fm account has been disconnected."))
    |> redirect(to: preference_path(conn, :edit))
  end

  def delete_history(conn, _params) do
    {:ok, _} = LastfmAccountService.delete_history!(current_resource(conn))

    conn
    |> put_flash(:success, gettext("Your listening history has been deleted."))
    |> redirect(to: preference_path(conn, :edit))
  end
end
