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

  def sanitized_page(page, max_page) do
    min(sanitized_page(page), max_page)
  end

  @doc """
  Caps a Scrivener page at the given number of pages so that pagination
  links never lead deeper than the cap.
  """
  def cap_total_pages(%Scrivener.Page{} = page, max_page) do
    %{page | total_pages: min(page.total_pages, max_page)}
  end
end
