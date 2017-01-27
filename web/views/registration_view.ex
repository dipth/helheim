defmodule Helheim.RegistrationView do
  use Helheim.Web, :view

  def breadcrumbs("new.html", _assigns), do: [{gettext("New Registration"), nil}]
end
