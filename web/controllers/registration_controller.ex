defmodule Helheim.RegistrationController do
  use Helheim.Web, :controller
  alias Helheim.User

  plug :put_layout, "app_special.html"

  def new(conn, _params) do
    changeset = User.registration_changeset(%User{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)
    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, gettext("User created!"))
        |> redirect(to: page_path(conn, :confirmation_pending))
      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end
end
