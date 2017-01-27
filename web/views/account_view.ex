defmodule Helheim.AccountView do
  use Helheim.Web, :view

  def breadcrumbs("edit.html", _assigns), do: [{gettext("Settings"), nil}, {gettext("Account"), nil}]
end
