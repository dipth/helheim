defmodule Helheim.PhotoAlbum do
  use Helheim.Web, :model
  alias Helheim.Repo
  alias Helheim.Photo

  schema "photo_albums" do
    belongs_to :user,        Helheim.User
    field      :title,       :string
    field      :description, :string
    field      :visibility,  :string

    has_many   :photos, Helheim.Photo

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :visibility])
    |> trim_fields([:title, :description])
    |> validate_required([:title, :visibility])
    |> validate_inclusion(:visibility, Helheim.Visibility.visibilities)
  end

  def viewable_by(query, owner, viewer) do
    if owner == viewer do
      query
    else
      from pa in query, where: pa.visibility == "public"
    end
  end

  def with_latest_photo(query) do
    photos_query = from p in Photo, order_by: [desc: p.inserted_at], limit: 1
    from pa in query, preload: [photos: ^photos_query]
  end

  def delete!(photo_album) do
    photos = assoc(photo_album, :photos) |> Repo.all
    Enum.each(photos, fn(p) -> Photo.delete!(p) end)
    Repo.delete!(photo_album)
  end
end
