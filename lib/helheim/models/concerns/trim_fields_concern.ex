defmodule Helheim.TrimFieldsConcern do
  defmacro __using__(_) do
    quote do
      defp trim_fields(changeset, fields) do
        fields = List.wrap(fields)
        Enum.reduce(fields, changeset, fn(field, changeset) ->
          trim_field changeset, field
        end)
      end

      defp trim_field(changeset, field) do
        case changeset do
          %Ecto.Changeset{changes: %{^field => value}} ->
            if value do
              put_change(changeset, field, String.trim(value))
            else
              changeset
            end
          _ ->
            changeset
        end
      end
    end
  end
end
