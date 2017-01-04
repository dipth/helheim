defmodule Altnation.ConfirmationView do
  use Altnation.Web, :view

  def breadcrumbs("new.html", _assigns), do: [{gettext("Resend confirmation e-mail"), nil}]
end
