defmodule HelheimWeb.Admin.User.VerificationController do
  use HelheimWeb, :controller
  alias Helheim.User

  def create(conn, %{"user_id" => user_id}) do
    user = Repo.get(User, user_id)
    admin = current_resource(conn)
    case User.verify!(user, admin) do
      {:ok, user} ->
        conn
        |> put_flash(:success, gettext("The user is now verified."))
        |> redirect(to: admin_user_path(conn, :show, user))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("The user is could not be verified!"))
        |> redirect(to: admin_user_path(conn, :show, user))
    end
  end

  def delete(conn, %{"user_id" => user_id}) do
    user = Repo.get(User, user_id)
    case User.unverify!(user) do
      {:ok, user} ->
        conn
        |> put_flash(:success, gettext("The user is no longer verified."))
        |> redirect(to: admin_user_path(conn, :show, user))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("The user is could not be unverified!"))
        |> redirect(to: admin_user_path(conn, :show, user))
    end
  end
end
