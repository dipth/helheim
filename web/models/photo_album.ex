defmodule Helheim.PhotoAlbum do
  use Helheim.Web, :model
  alias Helheim.Repo

  schema "photo_albums" do
    field :title,         :string
    field :description,   :string
    field :visibility,    :string
    field :visitor_count, :integer

    timestamps()

    belongs_to :user,   Helheim.User
    has_many   :photos, Helheim.Photo
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

  def delete!(photo_album) do
    photos = assoc(photo_album, :photos) |> Repo.all
    Parallel.pmap(photos, fn(p) -> Helheim.Photo.delete!(p) end)
    Repo.delete!(photo_album)
  end
end
