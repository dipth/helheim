defmodule Helheim.PaginationHelpers do
  import Scrivener.HTML

  def lpaginate(_conn, pagination) do
    pagination_links pagination, first:      true,
                                 last:       true,
                                 view_style: :bootstrap_v4
  end
end
