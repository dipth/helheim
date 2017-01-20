defmodule Altnation.ProfileView do
  use Altnation.Web, :view

  def breadcrumbs("show.html", _assigns), do: []
  def breadcrumbs("edit.html", _assigns), do: [{gettext("Settings"), nil}, {gettext("Profile"), nil}]
end
