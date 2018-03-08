defmodule Helheim.Block do
  use Helheim.Web, :model

  alias Helheim.Block
  alias Helheim.Repo
  alias Helheim.User

  schema "blocks" do
    belongs_to :blocker, User
    belongs_to :blockee, User
    field      :enabled, :boolean
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:enabled])
  end

  def for_blocker(query, blocker) do
    from b in query, where: b.blocker_id == ^blocker.id
  end

  def for_blockee(query, blockee) do
    from b in query, where: b.blockee_id == ^blockee.id
  end

  def involving_user(query, user) do
    from b in query, where: b.blocker_id == ^user.id or b.blockee_id == ^user.id
  end

  def order_by_blocker_and_blockee_username(query) do
    from b in query,
      join: blocker in User, on: blocker.id == b.blocker_id,  
      join: blockee in User, on: blockee.id == b.blockee_id,
      order_by: [blocker.username, blockee.username]
  end

  def order_by_blockee_username(query) do
    from b in query,
      join: u in User, on: u.id == b.blockee_id,
      order_by: u.username
  end

  def enabled(query) do
    from b in query, where: b.enabled == true
  end

  def blocked?(blocker_id, blockee) when is_integer(blocker_id) do
    Repo.get!(User, blocker_id)
    |> blocked?(blockee)
  end
  def blocked?(%User{} = blocker, blockee) do
    block = Block
            |> Block.for_blocker(blocker)
            |> Block.for_blockee(blockee)
            |> Block.enabled()
            |> Repo.one
    case block do
      nil -> false
        _ -> true
    end
  end

  def block!(%{id: blocker_id}, %{id: blockee_id}) when blocker_id == blockee_id, do: {:error, "Blocker and blockee must be different!"}
  def block!(blocker, blockee) do
    Block.changeset(existing_block(blocker, blockee) || new_block(blocker, blockee))
    |> Ecto.Changeset.put_change(:enabled, true)
    |> Repo.insert_or_update
  end

  def unblock!(%{id: blocker_id}, %{id: blockee_id}) when blocker_id == blockee_id, do: {:error, "Blocker and blockee must be different!"}
  def unblock!(blocker, blockee) do
    Ecto.Changeset.change(existing_block(blocker, blockee) || new_block(blocker, blockee))
    |> Ecto.Changeset.put_change(:enabled, false)
    |> Repo.insert_or_update
  end

  defp existing_block(blocker, blockee) do
    Block
    |> Block.for_blocker(blocker)
    |> Block.for_blockee(blockee)
    |> Repo.one
  end

  defp new_block(blocker, blockee) do
    Block.changeset(%Block{}, %{})
    |> Ecto.Changeset.put_assoc(:blocker, blocker)
    |> Ecto.Changeset.put_assoc(:blockee, blockee)
  end
end
