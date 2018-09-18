defmodule Helheim.TimeLimitedEditableConcern do
  alias Helheim.User

  defmacro __using__(_) do
    quote do
      @edit_timelimit_in_minutes 60
      def edit_timelimit_in_minutes, do: @edit_timelimit_in_minutes

      def editable_by?(struct, user) do
        User.admin?(user) || User.mod?(user) || (
          user_id(struct) == user.id &&
          Timex.after?(
            struct.inserted_at,
            Timex.shift(Timex.now, minutes: (edit_timelimit_in_minutes() * -1))
          )
        )
      end

      defp user_id(%{author_id: author_id}), do: author_id
      defp user_id(%{user_id: user_id}), do: user_id
    end
  end
end
