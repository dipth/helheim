defmodule Altnation.AccountView do
  use Altnation.Web, :view

  def breadcrumbs("edit.html", _assigns), do: [{gettext("Settings"), nil}, {gettext("Account"), nil}]
end
