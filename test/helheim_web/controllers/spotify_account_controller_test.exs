defmodule HelheimWeb.SpotifyAccountControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.SongListen
  alias Helheim.SpotifyAccount
  alias Helheim.Spotify.Client

  @token_data %{
    "access_token" => "an_access_token",
    "refresh_token" => "a_refresh_token",
    "expires_in" => 3600,
    "scope" => "user-read-recently-played"
  }

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "redirects to the spotify authorization url with a state param", %{conn: conn} do
      conn = post conn, "/spotify_account"
      location = redirected_to(conn)
      assert location =~ "https://accounts.spotify.com/authorize"
      %URI{query: query} = URI.parse(location)
      params = URI.decode_query(query)
      assert String.length(params["state"]) > 0
      assert params["scope"] == "user-read-recently-played"
    end
  end

  describe "create/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = post conn, "/spotify_account"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # callback/2
  describe "callback/2 when signed in" do
    setup [:create_and_sign_in_user]

    setup_with_mocks([
      {Client, [:passthrough], [
        exchange_code: fn
          "valid_code" -> {:ok, @token_data}
          _ -> {:error, :invalid_grant}
        end,
        me: fn _token -> {:ok, %{"id" => "spotify_uid"}} end
      ]}
    ], _context) do
      :ok
    end

    test "connects the user when given a valid code and matching state", %{conn: conn, user: user} do
      conn = post conn, "/spotify_account"
      state = state_from_redirect(conn)

      conn = get conn, "/spotify_account/callback", %{"code" => "valid_code", "state" => state}
      assert redirected_to(conn) == preference_path(conn, :edit)

      account = Repo.get_by!(SpotifyAccount, user_id: user.id)
      assert account.access_token == "an_access_token"
      assert account.spotify_user_id == "spotify_uid"
    end

    test "does not connect the user when the state does not match", %{conn: conn, user: user} do
      conn = post conn, "/spotify_account"

      conn = get conn, "/spotify_account/callback", %{"code" => "valid_code", "state" => "wrong_state"}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(SpotifyAccount, user_id: user.id)
    end

    test "does not connect the user when there is no state in the session", %{conn: conn, user: user} do
      conn = get conn, "/spotify_account/callback", %{"code" => "valid_code", "state" => "some_state"}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(SpotifyAccount, user_id: user.id)
    end

    test "does not connect the user when the code exchange fails", %{conn: conn, user: user} do
      conn = post conn, "/spotify_account"
      state = state_from_redirect(conn)

      conn = get conn, "/spotify_account/callback", %{"code" => "invalid_code", "state" => state}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(SpotifyAccount, user_id: user.id)
    end

    test "does not connect the user when the user denied the authorization", %{conn: conn, user: user} do
      conn = get conn, "/spotify_account/callback", %{"error" => "access_denied"}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(SpotifyAccount, user_id: user.id)
    end
  end

  describe "callback/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = get conn, "/spotify_account/callback", %{"code" => "valid_code", "state" => "some_state"}
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "deletes the spotify account but keeps the listens", %{conn: conn, user: user} do
      account = insert(:spotify_account, user: user)
      listen = insert(:song_listen, user: user)

      conn = delete conn, "/spotify_account"
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get(SpotifyAccount, account.id)
      assert Repo.get(SongListen, listen.id)
    end
  end

  describe "delete/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = delete conn, "/spotify_account"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete_history/2
  describe "delete_history/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "deletes the listens of the user but keeps the spotify account", %{conn: conn, user: user} do
      account = insert(:spotify_account, user: user)
      listen = insert(:song_listen, user: user)
      other_listen = insert(:song_listen)

      conn = delete conn, "/spotify_account/history"
      assert redirected_to(conn) == preference_path(conn, :edit)
      assert Repo.get(SpotifyAccount, account.id)
      refute Repo.get(SongListen, listen.id)
      assert Repo.get(SongListen, other_listen.id)
    end
  end

  describe "delete_history/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = delete conn, "/spotify_account/history"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  defp state_from_redirect(conn) do
    %URI{query: query} = URI.parse(redirected_to(conn))
    URI.decode_query(query)["state"]
  end
end
