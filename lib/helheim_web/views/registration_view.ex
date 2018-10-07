defmodule HelheimWeb.RegistrationView do
  use HelheimWeb, :view

  def breadcrumbs("new.html", _assigns), do: [{gettext("New Registration"), nil}]
end
