defmodule Helheim.PasswordResetController do
  use Helheim.Web, :controller
  alias Helheim.User
  alias Helheim.Email
  alias Helheim.Mailer

  plug :put_layout, "app_special.html"

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"password_reset" => reset_params}) do
    user = Repo.get_by(User, email: reset_params["email"])
    cond do
      user && User.confirmed?(user) ->
        send_reset_instructions(conn, user)
      user ->
        conn
        |> put_flash(:warning, gettext("You need to confirm your e-mail address before you can reset your password"))
        |> render("new.html")
      true ->
        conn
        |> put_flash(:warning, gettext("No user with that e-mail address!"))
        |> render("new.html")
    end
  end

  def show(conn, %{"id" => password_reset_token}) do
    user = Repo.get_by(User, password_reset_token: password_reset_token)

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:error, gettext("Token not found!"))
        |> redirect(to: page_path(conn, :index))
      User.password_reset_token_expired?(user) ->
        conn
        |> put_flash(:warning, gettext("Your password reset token has expired. Please request a new!"))
        |> redirect(to: password_reset_path(conn, :new))
      true ->
        changeset = User.new_password_changeset(user)
        conn
        |> render("show.html", changeset: changeset, password_reset_token: password_reset_token)
    end
  end

  def update(conn, %{"id" => password_reset_token, "user" => user_params}) do
    user = Repo.get_by(User, password_reset_token: password_reset_token)

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:info, gettext("Token not found!"))
        |> redirect(to: page_path(conn, :index))
      User.password_reset_token_expired?(user) ->
        conn
        |> put_flash(:warning, gettext("Your password reset token has expired. Please request a new!"))
        |> redirect(to: password_reset_path(conn, :new))
      true ->
        changeset = User.new_password_changeset(user, user_params)
        case Repo.update(changeset) do
          {:ok, user} ->
            conn
            |> Helheim.Auth.login(user)
            |> put_flash(:success, gettext("Your password has now been changed and you have been signed in!"))
            |> redirect(to: page_path(conn, :front_page))
          {:error, changeset} ->
            conn
            |> render("show.html", changeset: changeset, password_reset_token: password_reset_token)
        end
    end
  end

  defp send_reset_instructions(conn, user) do
    {:ok, user} = User.update_password_reset_token! user

    Email.password_reset_email(user)
    |> Mailer.deliver_later

    conn
    |> put_flash(:success, gettext("Password reset instructions sent!"))
    |> redirect(to: page_path(conn, :index))
  end
end
