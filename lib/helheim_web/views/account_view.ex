defmodule HelheimWeb.AccountView do
  use HelheimWeb, :view

  def breadcrumbs("edit.html", _assigns), do: [{gettext("Settings"), nil}, {gettext("Account"), nil}]
end
