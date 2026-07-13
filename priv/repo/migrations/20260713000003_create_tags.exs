defmodule Helheim.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:tags, ["lower(name)"], name: :tags_name_index)

    create table(:songs_tags) do
      add :song_id, references(:songs, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :position, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:songs_tags, [:song_id, :tag_id])
    create index(:songs_tags, [:tag_id])
  end
end
