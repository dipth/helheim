defmodule HelheimWeb.AccountController do
  use HelheimWeb, :controller
  alias Helheim.User
  alias Helheim.Auth.Guardian

  def edit(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.account_changeset(user)
    render conn, "edit.html", changeset: changeset
  end

  def update(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)
    changeset = User.account_changeset(user, user_params)
    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, gettext("Account updated!"))
        |> redirect(to: page_path(conn, :front_page))
      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    User.delete!(user)

    conn
    |> Guardian.Plug.sign_out()
    |> delete_resp_cookie("guardian_default_token")
    |> put_flash(:success, gettext("Hope to see you again some time!"))
    |> redirect(to: page_path(conn, :index))
  end
end
