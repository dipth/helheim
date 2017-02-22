defmodule Helheim.PaginationSanitization do
  def sanitized_page(nil), do: 1
  def sanitized_page(""), do: 1
  def sanitized_page(page) do
    page = String.to_integer page
    cond do
      page > 100 -> 100
      page < 1 -> 1
      true -> page
    end
  end
end
