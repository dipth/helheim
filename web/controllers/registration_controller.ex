defmodule Altnation.RegistrationController do
  use Altnation.Web, :controller
  alias Altnation.User
  alias Altnation.Email
  alias Altnation.Mailer

  plug :put_layout, "app_special.html"

  def new(conn, _params) do
    changeset = User.registration_changeset(%User{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)
    case Repo.insert(changeset) do
      {:ok, user} ->
        Email.registration_email(user)
        |> Mailer.deliver_later

        conn
        |> put_flash(:info, "User created!")
        |> redirect(to: page_path(conn, :confirmation_pending))
      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end
end
