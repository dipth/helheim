defmodule Altnation.Email do
  use Bamboo.Phoenix, view: Altnation.EmailView

  def registration_email(user) do
    base_email
    |> to(user.email)
    |> subject("Welcome to Altnation. Please confirm your e-mail address")
    |> assign(:user, user)
    |> render(:registration_email)
  end

  defp base_email do
    new_email
    |> from("Helheim<no-reply@helheim.dk>")
    |> put_html_layout({Altnation.LayoutView, "email.html"})
  end
end
