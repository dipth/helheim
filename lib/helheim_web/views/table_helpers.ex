defmodule HelheimWeb.TableHelpers do
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag

  def sort_link(text, value, params, path_func) do
    direction = sort_direction(params, value)
    new_params = Map.merge(params, %{"sort" => value, "direction" => direction})
    path = path_func.(new_params)

    link to: path do
      [sort_arrow(params["sort"], value, direction), " ", text]
    end
  end

  defp sort_direction(%{"sort" => sort, "direction" => "desc"}, value) when sort == value, do: "asc"
  defp sort_direction(%{"sort" => sort}, value) when sort == value, do: "desc"
  defp sort_direction(_, _), do: "asc"

  defp sort_arrow(sort, value, "asc") when sort == value, do: content_tag(:i, "", class: "fa fa-chevron-down")
  defp sort_arrow(sort, value, "desc") when sort == value, do: content_tag(:i, "", class: "fa fa-chevron-up")
  defp sort_arrow(_, _, _), do: ""
end
