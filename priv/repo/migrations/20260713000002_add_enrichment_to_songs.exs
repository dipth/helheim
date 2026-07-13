defmodule Helheim.Repo.Migrations.AddEnrichmentToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :mbid, :string
      add :artist_mbid, :string
      add :album_mbid, :string
      add :release_year, :integer
      add :duration_seconds, :integer
      add :cover_image_url_large, :string
      add :artist_id, references(:artists, on_delete: :nilify_all)
      add :enriched_at, :utc_datetime_usec
    end

    create index(:songs, [:artist_id])
    create index(:songs, [:id], where: "enriched_at IS NULL", name: :songs_unenriched_index)
  end
end
