defmodule Helheim.Email do
  use Bamboo.Phoenix, view: Helheim.EmailView
  import Helheim.Gettext

  def registration_email(email, confirmation_token) do
    base_email
    |> to(email)
    |> subject(gettext("Welcome to %{site_name}. Please confirm your e-mail address", site_name: gettext("Helheim")))
    |> assign(:confirmation_token, confirmation_token)
    |> render(:registration_email)
  end

  def password_reset_email(user) do
    base_email
    |> to(user.email)
    |> subject(gettext("Password reset instructions for %{site_name}", site_name: gettext("Helheim")))
    |> assign(:user, user)
    |> render(:password_reset_email)
  end

  defp base_email do
    new_email
    |> from("Helheim<no-reply@helheim.dk>")
    |> put_html_layout({Helheim.LayoutView, "email.html"})
  end
end
