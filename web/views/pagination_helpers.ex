defmodule Helheim.PaginationHelpers do
  import Kerosene.HTML
  import Helheim.Gettext

  def lpaginate(conn, pagination) do
    paginate conn, pagination,
      next_label: gettext("Next"),
      previous_label: gettext("Previous"),
      first_label: gettext("First"),
      last_label: gettext("Last")
  end
end
