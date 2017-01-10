defmodule Altnation.SessionControllerTest do
  use Altnation.ConnCase
  import Altnation.Factory

  describe "new/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/sessions/new"
      assert html_response(conn, 200) =~ gettext("Sign In")
    end
  end

  describe "create/2" do
    test "it logs in and redirects the user when submitting valid credentials", %{conn: conn} do
      user = insert(:user)
      conn = post conn, "/sessions", session: %{email: user.email, password: "password"}
      assert html_response(conn, 302)
      assert Guardian.Plug.current_resource(conn).id == user.id
    end

    test "it does not log the user in when submitting invalid credentials", %{conn: conn} do
      user = insert(:user)
      conn = post conn, "/sessions", session: %{email: user.email, password: "wrong"}
      assert html_response(conn, 200) =~ gettext("Wrong e-mail or password")
      refute Guardian.Plug.current_resource(conn)
    end
  end

  describe "delete/2" do
    test "it logs out and redirects the current user", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = delete conn, "/sessions/access"
      assert html_response(conn, 302)
      refute Guardian.Plug.current_resource(conn)
    end

    test "it just redirects when you are not signed in", %{conn: conn} do
      conn = delete conn, "/sessions/access"
      assert html_response(conn, 302)
    end
  end
end
