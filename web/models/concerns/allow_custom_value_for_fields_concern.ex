defmodule Helheim.AllowCustomValueForFieldsConcern do
  defmacro __using__(_) do
    quote do
      defp allow_custom_value_for_fields(changeset, field_sets) do
        field_sets = List.wrap(field_sets)
        Enum.reduce(field_sets, changeset, fn(field_set, changeset) ->
          allow_custom_value_for_field changeset, field_set
        end)
      end

      defp allow_custom_value_for_field(changeset, field_set) do
        {field, custom_field} = field_set
        case changeset do
          %Ecto.Changeset{changes: %{^field => "%%CUSTOM%%", ^custom_field => custom_value}} ->
            put_change(changeset, field, custom_value)
          %Ecto.Changeset{changes: %{^field => "%%CUSTOM%%"}} ->
            put_change(changeset, field, nil)
          _ ->
            changeset
        end
      end
    end
  end
end
