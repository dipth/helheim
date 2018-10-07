defmodule HelheimWeb.PreferenceControllerTest do
  use HelheimWeb.ConnCase
  alias Helheim.Repo
  alias Helheim.User

  ##############################################################################
  # edit/2
  describe "edit/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it returns a successful response when signed in", %{conn: conn} do
      conn = get conn, "/preferences/edit"
      assert html_response(conn, 200) =~ gettext("Preferences")
    end
  end

  describe "edit/2 when not signed in" do
    test "it redirects to the sign in page", %{conn: conn} do
      conn = get conn, "/preferences/edit"
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end

  ##############################################################################
  # update/2
  describe "update/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it allows the update of the users notification sound", %{conn: conn, user: user} do
      conn = put conn, "/preferences", user: %{notification_sound: "chime_1"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.notification_sound == "chime_1"
    end

    test "it allows enabling muting of notifications", %{conn: conn, user: user} do
      conn = put conn, "/preferences", user: %{mute_notifications: "true"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      assert user.mute_notifications
    end

    test "it allows disabling muting of notifications", %{conn: conn, user: user} do
      conn = put conn, "/preferences", user: %{mute_notifications: "false"}
      assert html_response(conn, 302)
      user = Repo.get(User, user.id)
      refute user.mute_notifications
    end
  end

  describe "update/2 when not signed in" do
    test "it redirects back to the sign in page", %{conn: conn} do
      conn = put conn, "/preferences", user: %{notification_sound: "chime_1"}
      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
