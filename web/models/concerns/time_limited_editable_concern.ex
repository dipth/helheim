defmodule Helheim.TimeLimitedEditableConcern do
  defmacro __using__(_) do
    quote do
      def editable_by?(struct, user) do
        Helheim.User.admin?(user) || (
          struct.user_id == user.id &&
          Timex.after?(struct.inserted_at, Timex.shift(Timex.now, minutes: -10))
        )
      end
    end
  end
end
