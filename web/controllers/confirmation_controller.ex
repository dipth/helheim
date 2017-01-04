defmodule Altnation.ConfirmationController do
  use Altnation.Web, :controller
  alias Altnation.User
  alias Altnation.Email
  alias Altnation.Mailer

  plug :put_layout, "app_special.html"

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"confirmation" => confirmation_params}) do
    user = Repo.get_by(User, email: confirmation_params["email"])
    if is_nil(user) do
      conn
      |> put_flash(:info, "No user with that e-mail address!")
      |> render("new.html")
    else
      send_confirmation(conn, user)
    end
  end

  def show(conn, %{"id" => confirmation_token}) do
    user = Repo.get_by(User, confirmation_token: confirmation_token)
    if is_nil(user) do
      conn
      |> put_flash(:info, "Token not found!")
      |> redirect(to: page_path(conn, :index))
    else
      confirm_user(conn, user)
    end
  end

  defp confirm_user(conn, user) do
    case User.confirm!(user) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User confirmed!")
        |> redirect(to: page_path(conn, :index))
      {:error, _changeset} ->
        conn
        |> put_flash(:info, "Unable to confirm!")
        |> redirect(to: page_path(conn, :index))
    end
  end

  defp send_confirmation(conn, user) do
    Email.registration_email(user)
    |> Mailer.deliver_later

    conn
    |> put_flash(:info, "Confirmation e-mail sent!")
    |> redirect(to: page_path(conn, :index))
  end
end
