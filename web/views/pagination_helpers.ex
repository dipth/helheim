defmodule Helheim.PaginationHelpers do
  import Scrivener.HTML

  def lpaginate(_conn, pagination, options \\ []) do
    options = Keyword.merge(options,
      first:      true,
      last:       true,
      view_style: :bootstrap_v4
    )
    pagination_links pagination, options
  end
end
