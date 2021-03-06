defmodule HelheimWeb.SessionControllerTest do
  use HelheimWeb.ConnCase

  describe "new/2" do
    test "it returns a successful response", %{conn: conn} do
      conn = get conn, "/sessions/new"
      assert html_response(conn, 200) =~ gettext("Sign In")
    end
  end

  describe "create/2" do
    test "it logs in and redirects the user when submitting valid credentials", %{conn: conn} do
      user = insert(:user)
      conn = post conn, "/sessions", session: %{email: user.email, password: "password", remember_me: "false"}
      assert html_response(conn, 302)
      assert Guardian.Plug.current_resource(conn).id == user.id
    end

    test "it does not log the user in when he has not yet confirmed his e-mail address", %{conn: conn} do
      user = insert(:user, confirmed_at: nil)
      conn = post conn, "/sessions", session: %{email: user.email, password: "password", remember_me: "false"}
      assert html_response(conn, 200) =~ gettext("You need to confirm your e-mail address before you can log in")
      refute Guardian.Plug.current_resource(conn)
    end

    test "it does not log the user in when submitting invalid credentials", %{conn: conn} do
      user = insert(:user)
      conn = post conn, "/sessions", session: %{email: user.email, password: "wrong", remember_me: "false"}
      assert html_response(conn, 200) =~ gettext("Wrong e-mail or password")
      refute Guardian.Plug.current_resource(conn)
    end

    test "it trims whitespace before checking credentials", %{conn: conn} do
      user = insert(:user)
      conn = post conn, "/sessions", session: %{email: "   #{user.email}   ", password: "password", remember_me: "false"}
      assert html_response(conn, 302)
      assert Guardian.Plug.current_resource(conn).id == user.id
    end
  end

  describe "delete/2" do
    test "it logs out and redirects the current user", %{conn: conn} do
      conn = conn |> sign_in(insert(:user))
      conn = get conn, "/sessions/sign_out"
      assert html_response(conn, 302)
      refute Guardian.Plug.current_resource(conn)
    end

    test "it just redirects when you are not signed in", %{conn: conn} do
      conn = get conn, "/sessions/sign_out"
      assert html_response(conn, 302)
    end
  end
end
