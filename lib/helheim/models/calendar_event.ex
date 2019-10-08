defmodule Helheim.CalendarEvent do
  use Helheim, :model
  use Arc.Ecto.Schema

  alias Helheim.CalendarEvent
  alias Helheim.Repo

  schema "calendar_events" do
    field :uuid,          :string
    field :title,         :string
    field :description,   :string
    field :starts_at,     :naive_datetime
    field :ends_at,       :naive_datetime
    field :location,      :string
    field :url,           :string
    field :image,         HelheimWeb.CalendarEventImage.Type
    field :approved_at,   :utc_datetime
    field :rejected_at,   :utc_datetime
    field :comment_count, :integer

    timestamps(type: :utc_datetime)

    belongs_to :user, Helheim.User
    has_many :comments, Helheim.Comment
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :starts_at, :ends_at, :location, :url])
    |> trim_fields([:title, :description, :location, :url])
    |> validate_required([:title, :description, :starts_at, :ends_at, :location])
    |> put_uuid()
    |> cast_attachments(params, [:image])
  end

  def approved(query) do
    from e in query,
    where: not is_nil(e.approved_at)
  end

  def pending(query) do
    from e in query,
    where: is_nil(e.approved_at) and is_nil(e.rejected_at)
  end

  def upcoming(query) do
    from e in query,
    where: e.ends_at > ^DateTime.utc_now
  end

  def chronological(query) do
    from e in query,
    order_by: [asc: e.starts_at, asc: e.ends_at, asc: e.inserted_at]
  end

  def pending_count() do
    calendar_events = CalendarEvent |> CalendarEvent.pending()
    Repo.one(from e in calendar_events, select: count("*"))
  end

  def approved?(%{approved_at: nil}), do: false
  def approved?(_), do: true

  def rejected?(%{rejected_at: nil}), do: false
  def rejected?(_), do: true

  def pending?(%{approved_at: nil, rejected_at: nil}), do: true
  def pending?(_), do: false

  def approve!(calendar_event) do
    case calendar_event.approved_at do
      nil ->
        Ecto.Changeset.change(calendar_event, approved_at: DateTime.utc_now)
        |> Repo.update
      _ -> {:ok, calendar_event}
    end
  end

  def reject!(calendar_event) do
    case calendar_event.rejected_at do
      nil ->
        Ecto.Changeset.change(calendar_event, rejected_at: DateTime.utc_now)
        |> Repo.update
      _ -> {:ok, calendar_event}
    end
  end

  ### PRIVATE

  defp put_uuid(changeset) do
    case get_field(changeset, :uuid) do
      nil -> put_change(changeset, :uuid, SecureRandom.uuid())
      _ ->   changeset
    end
  end
end
