defmodule HelheimWeb.PaginationSanitization do
  def sanitized_page(nil), do: 1
  def sanitized_page(""), do: 1
  def sanitized_page(page) do
    # The page comes straight off the query string, so anything at all can turn
    # up in it. Parsing rather than String.to_integer/1 keeps "?page=abc" - which
    # crawlers and hand-edited urls do produce - from raising its way to a 500.
    case Integer.parse(page) do
      {page, ""} -> clamp_page(page)
      _ -> 1
    end
  end

  def sanitized_page(page, max_page) do
    min(sanitized_page(page), max_page)
  end

  defp clamp_page(page) do
    cond do
      page > 1000 -> 1000
      page < 1 -> 1
      true -> page
    end
  end

  @doc """
  Caps a Scrivener page at the given number of pages so that pagination
  links never lead deeper than the cap.
  """
  def cap_total_pages(%Scrivener.Page{} = page, max_page) do
    %{page | total_pages: min(page.total_pages, max_page)}
  end

  # The full list pages are capped at 100 pages to preserve performance.
  @max_pages 100

  @doc """
  Paginates a full list page, clamping both the requested page and the
  advertised page count to the cap.
  """
  def capped_paginate(query, params) do
    query
    |> Helheim.Repo.paginate(page: sanitized_page(params["page"], @max_pages))
    |> cap_total_pages(@max_pages)
  end
end
