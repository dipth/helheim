defmodule Helheim.Photo do
  use Helheim.Web, :model
  use Arc.Ecto.Schema
  alias Helheim.Repo
  alias Helheim.PhotoFile

  @max_file_size 1 * 1000 * 1000 # MB
  def max_file_size, do: @max_file_size

  @max_total_file_size_per_user 25 * 1000 * 1000 # MB
  def max_total_file_size_per_user, do: @max_total_file_size_per_user

  schema "photos" do
    field      :uuid,          :string
    field      :title,         :string
    field      :description,   :string
    field      :file,          PhotoFile.Type
    field      :file_size,     :integer
    field      :visitor_count, :integer

    timestamps()

    belongs_to :photo_album, Helheim.PhotoAlbum
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description])
    |> trim_fields([:title, :description])
    |> put_uuid()
    |> cast_attachments(params, [:file])
    |> validate_required([:title, :file])
    |> unique_constraint(:uuid)
  end

  def newest(query) do
    from p in query,
    order_by: [desc: p.inserted_at]
  end

  def newest_public_photos_by(user, limit) do
    Repo.all from p in Helheim.Photo,
      join:     pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
      where:    pa.user_id == ^user.id and pa.visibility == "public",
      order_by: [desc: p.inserted_at],
      limit:    ^limit,
      preload:  :photo_album
  end

  def newest_public_photos(limit) do
    Repo.all from p in Helheim.Photo,
      join:     pa in Helheim.PhotoAlbum, on: pa.id == p.photo_album_id,
      where:    pa.visibility == "public",
      order_by: [desc: p.inserted_at],
      limit:    ^limit,
      preload:  [photo_album: :user]
  end

  def chronologically(query) do
    from p in query,
    order_by: [asc: p.inserted_at]
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
end
