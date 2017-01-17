defmodule Altnation.ProfileView do
  use Altnation.Web, :view

  def breadcrumbs("edit.html", _assigns), do: [{gettext("Settings"), nil}, {gettext("Profile"), nil}]
end
