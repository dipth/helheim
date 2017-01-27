defmodule Helheim.ConfirmationView do
  use Helheim.Web, :view

  def breadcrumbs("new.html", _assigns), do: [{gettext("Resend confirmation e-mail"), nil}]
end
