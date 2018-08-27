defmodule Helheim.PaginationHelpers do
  import Helheim.Gettext
  import Phoenix.HTML.{Tag, Link}

  def pagination_links(conn, collection, params \\ %{}) do
    content_tag(:nav) do
      content_tag(:ul, class: "pagination") do
        [
          first_page(conn, collection, params),
          previous_page(conn, collection, params),
          current_page(conn, collection, params),
          next_page(conn, collection, params),
          last_page(conn, collection, params)
        ]
      end
    end
  end

  defp first_page(_conn, %{page_number: 1}, _params), do: ""
  defp first_page(conn, _collection, params) do
    content_tag(:li, class: "page-item") do
      link(to: page_url(conn, 1, params), class: "page-link") do
        content_tag(:i, "", class: "fa fa-fast-backward")
      end
    end
  end

  defp previous_page(_conn, %{page_number: 1}, _params), do: ""
  defp previous_page(conn, collection, params) do
    content_tag(:li, class: "page-item") do
      link(to: page_url(conn, collection.page_number - 1, params), class: "page-link") do
        content_tag(:i, "", class: "fa fa-backward")
      end
    end
  end

  defp current_page(_conn, collection, _params) do
    content_tag(:li, class: "page-item active") do
      label = gettext("%{page} of %{total}", page: collection.page_number, total: collection.total_pages)
      content_tag(:a, label, class: "page-link")
    end
  end

  defp next_page(_conn, %{page_number: cur_pg, total_pages: tot_pg}, _params) when cur_pg >= tot_pg, do: ""
  defp next_page(conn, collection, params) do
    content_tag(:li, class: "page-item") do
      link(to: page_url(conn, collection.page_number + 1, params), class: "page-link") do
        content_tag(:i, "", class: "fa fa-forward")
      end
    end
  end

  defp last_page(_conn, %{page_number: cur_pg, total_pages: tot_pg}, _params) when cur_pg == tot_pg, do: ""
  defp last_page(conn, collection, params) do
    content_tag(:li, class: "page-item") do
      link(to: page_url(conn, collection.total_pages, params), class: "page-link") do
        content_tag(:i, "", class: "fa fa-fast-forward")
      end
    end
  end

  defp page_url(conn, page_number, params) do
    Phoenix.Controller.current_path(conn, Map.merge(params, %{page: page_number}))
  end
end
