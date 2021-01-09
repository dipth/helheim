defmodule HelheimWeb.SpotifyControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.User

  ##############################################################################
  # authorize/2
  describe "authorize/2 when signed in" do
    setup [:create_and_sign_in_user]

    test_with_mock "it redirects to the Spotify OAuth page", %{conn: conn},
      Spotify.Authorization, [], [url: fn() -> "https://testing.spotify.com/oauth_url" end] do

      conn = get conn, "/spotify/authorize"
      assert redirected_to(conn) =~ "https://testing.spotify.com/oauth_url"
    end
  end

  describe "authorize/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/spotify/authorize"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # callback/2
  describe "callback/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "stores the resulting access tokens on the user and redirects to the front page", %{conn: conn, user: user} do
      with_mocks([
        {Spotify.Authentication, [], [authenticate: fn(conn, %{"code" => "thiscodeisjustfortesting"}) -> {:ok, conn} end]},
        {Spotify.Cookies, [], [
          get_access_token: fn(_conn) -> "testaccesstoken" end,
          get_refresh_token: fn(_conn) -> "testrefreshtoken" end
        ]}
      ]) do
        conn = get conn, "/spotify/callback", [code: "thiscodeisjustfortesting"]
        assert page_path(conn, :front_page)
        user = Repo.get(User, user.id)
        assert user.spotify_access_token == "testaccesstoken"
        assert user.spotify_refresh_token == "testrefreshtoken"
      end
    end
  end

  describe "callback/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/spotify/callback", [code: "thiscodeisjustfortesting"]
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
