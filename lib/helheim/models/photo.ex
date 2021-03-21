defmodule Helheim.Photo do
  use Helheim, :model

  use Arc.Ecto.Schema
  alias Helheim.Repo
  alias HelheimWeb.PhotoFile
  alias Helheim.Photo
  alias Helheim.PhotoAlbum

  @max_file_size 5 * 1000 * 1000 # MB
  def max_file_size, do: @max_file_size

  schema "photos" do
    field      :uuid,          :string
    field      :title,         :string
    field      :description,   :string
    field      :file,          PhotoFile.Type
    field      :file_size,     :integer
    field      :nsfw,          :boolean
    field      :visitor_count, :integer
    field      :comment_count, :integer
    field      :position,      :integer

    timestamps(type: :utc_datetime_usec)

    belongs_to :photo_album,         Helheim.PhotoAlbum
    has_many   :visitor_log_entries, Helheim.VisitorLogEntry
    has_many   :comments,            Helheim.Comment
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :nsfw])
    |> trim_fields([:title, :description])
    |> put_uuid()
    |> resolve_position()
    |> cast_attachments(params, [:file])
    |> validate_required([:title, :file])
    |> unique_constraint(:uuid)
  end

  def update_changeset(struct, user_photo_albums, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :nsfw, :photo_album_id])
    |> trim_fields([:title, :description])
    |> put_uuid()
    |> resolve_position()
    |> cast_attachments(params, [:file])
    |> validate_required([:title, :file])
    |> unique_constraint(:uuid)
    |> validate_inclusion(:photo_album_id, Enum.map(user_photo_albums, &(&1.id)))
  end

  def update_file(photo, params) do
    photo
    |> cast_attachments(params, ~w(), ~w(file))
  end

  def newest(query) do
    from p in query,
    order_by: [desc: p.inserted_at]
  end

  def public(query) do
    from p in query,
    join:  pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
    where: pa.visibility == "public"
  end

  def newest_for_frontpage(user, limit, ignoree_ids \\ []) do
    sq = from(
      p in      (Photo |> Photo.visible_by(user) |> Photo.not_private()),
      join:     pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
      where:    pa.user_id not in ^ignoree_ids,
      group_by: pa.user_id,
      select:   %{last_public_photo_id: max(p.id)},
      order_by: [desc: max(p.id)],
      limit:    ^limit
    )
    from(
      p in      Helheim.Photo,
      join:     sub_p in subquery(sq), on: p.id == sub_p.last_public_photo_id,
      order_by: [desc: p.inserted_at],
      preload:  [photo_album: :user]
    ) |> Repo.all
  end

  def chronologically(query) do
    from p in query,
    order_by: [asc: p.inserted_at]
  end

  def in_positional_order(query) do
    from p in query,
    order_by: [p.position, p.inserted_at]
  end

  def visible_by(query, user) do
    verified = Helheim.User.verified?(user)

    from p in query,
    join:  pa in PhotoAlbum, on: pa.id == p.photo_album_id,
    where: pa.visibility == "public" or pa.user_id == ^user.id or (pa.visibility == "verified_only" and ^verified) or (
      (pa.visibility == "friends_only" or pa.visibility == "verified_only") and fragment(
        "EXISTS(?)",
        fragment(
          "
            SELECT 1 FROM friendships
            WHERE
              friendships.accepted_at IS NOT NULL AND
              friendships.sender_id IN (?,?) AND
              friendships.recipient_id IN (?,?)
          ", pa.user_id, ^user.id, pa.user_id, ^user.id
        )
      )
    )
  end

  def not_private(query) do
    from p in query,
    join: pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
    where: pa.visibility != "private"
  end

  def by(query, user) do
    from p in query,
    join: pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
    where: pa.user_id == ^user.id
  end

  def previous(photo) do
    from(
      p in Helheim.Photo,
      where:    p.photo_album_id == ^photo.photo_album_id,
      where:    p.position < ^photo.position or (p.position == ^photo.position and p.inserted_at < ^photo.inserted_at),
      order_by: [desc: p.position, desc: p.inserted_at],
      limit:    1
    ) |> Repo.one
  end

  def next(photo) do
    from(
      p in Helheim.Photo,
      where:    p.photo_album_id == ^photo.photo_album_id,
      where:    p.position > ^photo.position or (p.position == ^photo.position and p.inserted_at > ^photo.inserted_at),
      order_by: [p.position, p.inserted_at],
      limit:    1
    ) |> Repo.one
  end

  def total_used_space_by(user) do
    ((from p in Helheim.Photo,
      join:   pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
      where:  pa.user_id == ^user.id,
      select: sum(p.file_size))
    |> Repo.one) || 0
  end

  def delete!(photo) do
    path        = PhotoFile.url({photo.file, photo})
    [path | _]  = String.split path, "?"
    :ok = PhotoFile.delete({path, photo})
    Repo.delete!(photo)
  end

  defp put_uuid(changeset) do
    case get_field(changeset, :uuid) do
      nil -> put_change(changeset, :uuid, SecureRandom.uuid())
      _ ->   changeset
    end
  end

  defp resolve_position(changeset) do
    case get_field(changeset, :position) do
      nil ->
        photo_album_id = get_field(changeset, :photo_album_id)
        put_change(changeset, :position, next_position(photo_album_id))
      _ -> changeset
    end
  end

  defp next_position(photo_album_id) do
    (((from p in Helheim.Photo,
    where:  p.photo_album_id == ^photo_album_id,
    select: max(p.position))
    |> Repo.one) || -1) + 1
  end
end
