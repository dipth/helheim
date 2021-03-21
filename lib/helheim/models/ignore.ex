defmodule Helheim.Ignore do
  use Helheim, :model

  alias Helheim.Ignore
  alias Helheim.Repo
  alias Helheim.User

  schema "ignores" do
    belongs_to :ignorer, User
    belongs_to :ignoree, User
    field      :enabled, :boolean
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:enabled])
  end

  def for_ignorer(query, ignorer) do
    from b in query, where: b.ignorer_id == ^ignorer.id
  end

  def for_ignoree(query, ignoree) do
    from b in query, where: b.ignoree_id == ^ignoree.id
  end

  def involving_user(query, user) do
    from b in query, where: b.ignorer_id == ^user.id or b.ignoree_id == ^user.id
  end

  def order_by_ignorer_and_ignoree_username(query) do
    from b in query,
      join: ignorer in User, on: ignorer.id == b.ignorer_id,
      join: ignoree in User, on: ignoree.id == b.ignoree_id,
      order_by: [ignorer.username, ignoree.username]
  end

  def order_by_ignoree_username(query) do
    from b in query,
      join: u in User, on: u.id == b.ignoree_id,
      order_by: u.username
  end

  def enabled(query) do
    from b in query, where: b.enabled == true
  end

  def ignored?(ignorer_id, ignoree) when is_integer(ignorer_id) do
    Repo.get!(User, ignorer_id)
    |> ignored?(ignoree)
  end
  def ignored?(%User{} = ignorer, ignoree) do
    ignore = Ignore
      |> Ignore.for_ignorer(ignorer)
      |> Ignore.for_ignoree(ignoree)
      |> Ignore.enabled()
      |> Repo.one
    case ignore do
      nil -> false
        _ -> true
    end
  end

  def ignore!(%{id: ignorer_id}, %{id: ignoree_id}) when ignorer_id == ignoree_id, do: {:error, "ignorer and ignoree must be different!"}
  def ignore!(ignorer, ignoree) do
    Ignore.changeset(existing_ignore(ignorer, ignoree) || new_ignore(ignorer, ignoree))
    |> Ecto.Changeset.put_change(:enabled, true)
    |> Repo.insert_or_update
  end

  def unignore!(%{id: ignorer_id}, %{id: ignoree_id}) when ignorer_id == ignoree_id, do: {:error, "ignorer and ignoree must be different!"}
  def unignore!(ignorer, ignoree) do
    Ecto.Changeset.change(existing_ignore(ignorer, ignoree) || new_ignore(ignorer, ignoree))
    |> Ecto.Changeset.put_change(:enabled, false)
    |> Repo.insert_or_update
  end

  def get_ignore_map do
    query = Ignore |> Ignore.enabled()
    query = from i in query,
      group_by: i.ignorer_id,
      select: {i.ignorer_id, fragment("array_agg(?)", i.ignoree_id)}
    Repo.all(query)
    |> Enum.into(%{})
  end

  defp existing_ignore(ignorer, ignoree) do
    Ignore
    |> Ignore.for_ignorer(ignorer)
    |> Ignore.for_ignoree(ignoree)
    |> Repo.one
  end

  defp new_ignore(ignorer, ignoree) do
    Ignore.changeset(%Ignore{}, %{})
    |> Ecto.Changeset.put_assoc(:ignorer, ignorer)
    |> Ecto.Changeset.put_assoc(:ignoree, ignoree)
  end
end
