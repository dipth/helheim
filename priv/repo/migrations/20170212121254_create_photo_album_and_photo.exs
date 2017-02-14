defmodule Helheim.Repo.Migrations.CreatePhotoAlbumAndPhoto do
  use Ecto.Migration

  def change do
    create table(:photo_albums) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :title,       :string, null: false
      add :description, :text
      add :visibility,  :text, null: false, default: "private"
      timestamps()
    end

    create index(:photo_albums, [:user_id])

    create table(:photos) do
      add :uuid,           :string,  null: false
      add :photo_album_id, references(:photo_albums, on_delete: :delete_all)
      add :title,          :string
      add :description,    :text
      add :file,           :string
      add :file_size,      :integer
      timestamps()
    end

    create index(:photos, [:photo_album_id])
    create unique_index(:photos, [:uuid])
  end
end
