defmodule Altnation.BreadcrumbsDefaults do
  defmacro __using__(_) do
    quote do
      def breadcrumbs(_other, _assigns), do: []

      defoverridable [breadcrumbs: 2]
    end
  end
end
