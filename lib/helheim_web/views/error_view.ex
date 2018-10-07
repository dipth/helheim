defmodule HelheimWeb.ErrorView do
  use HelheimWeb, :view

  def render("403.html", _assigns) do
    "Forbidden"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end
end
