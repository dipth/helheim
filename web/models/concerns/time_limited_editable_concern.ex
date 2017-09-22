defmodule Helheim.TimeLimitedEditableConcern do
  defmacro __using__(_) do
    quote do
      @edit_timelimit_in_minutes 60
      def edit_timelimit_in_minutes, do: @edit_timelimit_in_minutes

      def editable_by?(struct, user) do
        Helheim.User.admin?(user) || (
          struct.user_id == user.id &&
          Timex.after?(
            struct.inserted_at,
            Timex.shift(Timex.now, minutes: (edit_timelimit_in_minutes() * -1))
          )
        )
      end
    end
  end
end
