defmodule Altnation.RegistrationView do
  use Altnation.Web, :view

  def breadcrumbs("new.html", _assigns), do: [{gettext("New Registration"), nil}]
end
