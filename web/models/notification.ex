defmodule Helheim.Notification do
  use Helheim.Web, :model
  alias Helheim.Repo

  schema "notifications" do
    belongs_to :user,    Helheim.User
    field      :title,   :string
    field      :icon,    :string
    field      :path,    :string
    field      :read_at, Calecto.DateTimeUTC

    timestamps()
  end

  def newest(query) do
    from n in query,
    order_by: [desc: n.inserted_at]
  end

  def unread(query) do
    from n in query,
    where: is_nil(n.read_at)
  end

  def mark_as_read!(notification) do
    Ecto.Changeset.change(notification, read_at: DateTime.utc_now)
    |> Repo.update
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :icon, :path])
    |> trim_fields([:title, :icon, :path])
    |> validate_required([:title])
  end
end
