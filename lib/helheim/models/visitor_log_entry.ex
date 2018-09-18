defmodule Helheim.VisitorLogEntry do
  use Helheim, :model

  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.VisitorLogEntry
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.PhotoAlbum
  alias Helheim.Photo

  schema "visitor_log_entries" do
    timestamps()

    belongs_to :user,        User
    belongs_to :blog_post,   BlogPost
    belongs_to :photo_album, PhotoAlbum
    belongs_to :photo,       Photo
    belongs_to :profile,     User
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
  end

  def newest(query) do
    from e in query,
      order_by: [desc: e.updated_at]
  end

  def track!(user, %BlogPost{} = subject), do: track!(user, subject.user_id, subject, :blog_post)
  def track!(user, %PhotoAlbum{} = subject), do: track!(user, subject.user_id, subject, :photo_album)
  def track!(user, %Photo{} = subject), do: track!(user, subject.photo_album.user_id, subject, :photo)
  def track!(user, %User{} = subject), do: track!(user, subject.id, subject, :profile)
  defp track!(visitor, owner_id, subject, subject_type) do
    attrs = [user: visitor] |> Keyword.put(subject_type, subject)

    if attrs[:user].id != owner_id do
      entry = entry(attrs)
      Multi.new
      |> insert_or_update_entry(entry)
      |> update_visitor_count(entry, subject)
      |> Repo.transaction
    else
      {:error, "User must not be the owner"}
    end
  end

  defp entry(attrs) do
    case find_existing_entry(attrs) do
      nil   -> build_new_entry(attrs)
      entry -> VisitorLogEntry.changeset(entry)
    end
    |> Ecto.Changeset.change(updated_at: DateTime.utc_now)
  end

  defp insert_or_update_entry(multi, changeset) do
    case changeset.data.__meta__.state do
      :built  -> multi |> Multi.insert(:entry, changeset)
      :loaded -> multi |> Multi.update(:entry, changeset)
      _       -> multi
    end
  end

  defp update_visitor_count(multi, changeset, %BlogPost{}   = subject), do: update_visitor_count(multi, changeset, BlogPost,   subject.id)
  defp update_visitor_count(multi, changeset, %PhotoAlbum{} = subject), do: update_visitor_count(multi, changeset, PhotoAlbum, subject.id)
  defp update_visitor_count(multi, changeset, %Photo{}      = subject), do: update_visitor_count(multi, changeset, Photo,      subject.id)
  defp update_visitor_count(multi, changeset, %User{}       = subject), do: update_visitor_count(multi, changeset, User,       subject.id)
  defp update_visitor_count(multi, changeset, model, id) do
    if should_increment_visitor_count?(changeset) do
      multi |> Multi.update_all(:visitor_count, (model |> where(id: ^id)), inc: [visitor_count: 1])
    else
      multi
    end
  end

  defp should_increment_visitor_count?(changeset) do
    changeset.data.__meta__.state == :built ||
      Timex.before?(changeset.data.updated_at, Timex.shift(Timex.now, minutes: -30))
  end

  defp find_existing_entry(attrs) do
    VisitorLogEntry |> apply_filters(attrs) |> Repo.one
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn(criteria, query) -> apply_filter(criteria, query) end)
  end

  defp apply_filter(criteria, query) do
    {property, value} = criteria
    field_name        = String.to_atom("#{property}_id")
    field_value       = value.id
    from e in query,
      where: field(e, ^field_name) == ^field_value
  end

  defp build_new_entry(attrs) do
    VisitorLogEntry.changeset(%VisitorLogEntry{}) |> apply_attrs(attrs)
  end

  defp apply_attrs(struct, attrs) do
    Enum.reduce(attrs, struct, fn(attr, struct) -> apply_attr(attr, struct) end)
  end

  defp apply_attr(attr, struct) do
    {property, value} = attr
    struct |> Ecto.Changeset.put_assoc(property, value)
  end
end
