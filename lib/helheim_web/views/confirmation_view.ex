defmodule HelheimWeb.ConfirmationView do
  use HelheimWeb, :view

  def breadcrumbs("new.html", _assigns), do: [{gettext("Resend confirmation e-mail"), nil}]
end
