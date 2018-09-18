defmodule HelheimWeb.PaginationSanitization do
  def sanitized_page(nil), do: 1
  def sanitized_page(""), do: 1
  def sanitized_page(page) do
    page = String.to_integer page
    cond do
      page > 1000 -> 1000
      page < 1 -> 1
      true -> page
    end
  end
end
