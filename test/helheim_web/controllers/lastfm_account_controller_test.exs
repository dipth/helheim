defmodule HelheimWeb.LastfmAccountControllerTest do
  use HelheimWeb.ConnCase
  import Mock
  alias Helheim.SongListen
  alias Helheim.LastfmAccount
  alias Helheim.Lastfm.Client

  ##############################################################################
  # create/2
  describe "create/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "redirects to the last.fm authorization url with a callback on the request host", %{conn: conn} do
      conn = post conn, "/lastfm_account"
      location = redirected_to(conn)
      assert location =~ "https://www.last.fm/api/auth"
      %URI{query: query} = URI.parse(location)
      params = URI.decode_query(query)
      assert params["api_key"] == "lastfm_test_api_key"
      %URI{host: cb_host, path: cb_path} = URI.parse(params["cb"])
      assert cb_host == conn.host
      assert cb_path == "/lastfm_account/callback"
    end

    test "keeps the callback on the host the user is browsing on", %{conn: conn} do
      conn = %{conn | host: "apex-domain.example"}
      conn = post conn, "/lastfm_account"
      %URI{query: query} = URI.parse(redirected_to(conn))
      %URI{host: cb_host} = URI.parse(URI.decode_query(query)["cb"])
      assert cb_host == "apex-domain.example"
    end
  end

  describe "create/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = post conn, "/lastfm_account"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # callback/2
  describe "callback/2 when signed in" do
    setup [:create_and_sign_in_user]

    setup_with_mocks([
      {Client, [:passthrough], [
        get_session: fn
          "valid_token" -> {:ok, %{username: "melomaniac", session_key: "a_session_key"}}
          _ -> {:error, {:api_error, 4, "Invalid authentication token supplied"}}
        end
      ]}
    ], _context) do
      :ok
    end

    test "connects the user when the connect flow was started from this session", %{conn: conn, user: user} do
      conn = post conn, "/lastfm_account"

      conn = get conn, "/lastfm_account/callback", %{"token" => "valid_token"}
      assert redirected_to(conn) == preference_path(conn, :edit)

      account = Repo.get_by!(LastfmAccount, user_id: user.id)
      assert account.username == "melomaniac"
      assert account.session_key == "a_session_key"
    end

    test "does not connect the user when the connect flow was not started from this session", %{conn: conn, user: user} do
      conn = get conn, "/lastfm_account/callback", %{"token" => "valid_token"}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(LastfmAccount, user_id: user.id)
    end

    test "does not connect the user when the token exchange fails", %{conn: conn, user: user} do
      conn = post conn, "/lastfm_account"

      conn = get conn, "/lastfm_account/callback", %{"token" => "invalid_token"}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(LastfmAccount, user_id: user.id)
    end

    test "does not connect the user when no token is given", %{conn: conn, user: user} do
      conn = post conn, "/lastfm_account"

      conn = get conn, "/lastfm_account/callback", %{}
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get_by(LastfmAccount, user_id: user.id)
    end
  end

  describe "callback/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = get conn, "/lastfm_account/callback", %{"token" => "valid_token"}
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete/2
  describe "delete/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "deletes the lastfm account but keeps the listens", %{conn: conn, user: user} do
      account = insert(:lastfm_account, user: user)
      listen = insert(:song_listen, user: user)

      conn = delete conn, "/lastfm_account"
      assert redirected_to(conn) == preference_path(conn, :edit)
      refute Repo.get(LastfmAccount, account.id)
      assert Repo.get(SongListen, listen.id)
    end
  end

  describe "delete/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = delete conn, "/lastfm_account"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # delete_history/2
  describe "delete_history/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "deletes the listens of the user but keeps the lastfm account", %{conn: conn, user: user} do
      account = insert(:lastfm_account, user: user)
      listen = insert(:song_listen, user: user)
      other_listen = insert(:song_listen)

      conn = delete conn, "/lastfm_account/history"
      assert redirected_to(conn) == preference_path(conn, :edit)
      assert Repo.get(LastfmAccount, account.id)
      refute Repo.get(SongListen, listen.id)
      assert Repo.get(SongListen, other_listen.id)
    end
  end

  describe "delete_history/2 when not signed in" do
    test "redirects to the login page", %{conn: conn} do
      conn = delete conn, "/lastfm_account/history"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
