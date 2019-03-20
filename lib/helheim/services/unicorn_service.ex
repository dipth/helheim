defmodule Helheim.UnicornService do
  import Ecto.Query

  alias Helheim.CommentService
  alias Helheim.Repo
  alias Helheim.User

  def call(%{unicorn_at: unicorn_at} = user) when not is_nil(unicorn_at), do: {:ok, user}
  def call(user) do
    with {:ok, rainbow_unicorn} <- find_rainbow_unicorn(),
         {:ok, user} <- mark_user_as_unicorn(user),
         {:ok, %{comment: comment}} <- write_guest_book_entry(rainbow_unicorn, user)
    do
      IO.inspect [rainbow_unicorn, user, comment]
      {:ok, user}
    end
  end

  defp find_rainbow_unicorn do
    rainbow_unicorn = from(u in User, where: u.username == "rainbow_unicorn", limit: 1) |> Repo.one!()
    {:ok, rainbow_unicorn}
  end

  defp mark_user_as_unicorn(user) do
    Ecto.Changeset.change(user, %{unicorn_at: DateTime.utc_now})
    |> Repo.update()
  end

  defp write_guest_book_entry(rainbow_unicorn, user) do
    CommentService.create!(rainbow_unicorn, user, "All hail @rainbow_unicorn!!!")
  end
end
