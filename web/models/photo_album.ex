defmodule Helheim.PhotoAlbum do
  use Helheim.Web, :model
  alias Helheim.Repo
  alias Helheim.Photo

  schema "photo_albums" do
    field :title,         :string
    field :description,   :string
    field :visibility,    :string
    field :visitor_count, :integer
    field :comment_count, :integer

    timestamps()

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

  def viewable_by(query, owner, viewer) do
    if owner.id == viewer.id do
      query
    else
      from pa in query, where: pa.visibility == "public"
    end
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
