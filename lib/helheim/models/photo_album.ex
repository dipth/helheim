defmodule Helheim.PhotoAlbum do
  use Helheim, :model

  alias Helheim.Repo
  alias Helheim.Photo

  schema "photo_albums" do
    field :title,         :string
    field :description,   :string
    field :visibility,    :string
    field :visitor_count, :integer
    field :comment_count, :integer

    timestamps(type: :utc_datetime_usec)

    belongs_to :user,                Helheim.User
    has_many   :photos,              Helheim.Photo
    has_many   :visitor_log_entries, Helheim.VisitorLogEntry
    has_many   :comments,            Helheim.Comment
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :visibility])
    |> trim_fields([:title, :description])
    |> validate_required([:title, :visibility])
    |> validate_inclusion(:visibility, Helheim.Visibility.visibilities)
  end

  def visible_by(query, user) do
    verified = Helheim.User.verified?(user)

    from pa in query,
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

  def reposition_photos!(photo_album, photo_ids) do
    from(
      p in Photo,
      where: p.photo_album_id == ^photo_album.id,
      update: [set: [position: fragment("array_position(?, id) - 1", ^photo_ids)]]
    ) |> Repo.update_all([])
  end

  def delete!(photo_album) do
    photos = assoc(photo_album, :photos) |> Repo.all
    Parallel.pmap(photos, fn(p) -> Helheim.Photo.delete!(p) end)
    Repo.delete!(photo_album)
  end
end
