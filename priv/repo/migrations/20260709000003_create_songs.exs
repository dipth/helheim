defmodule Helheim.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :spotify_track_id, :string, null: false
      add :title, :string, null: false
      add :artist_name, :string, null: false
      add :artist_spotify_id, :string
      add :album_name, :string
      add :album_spotify_id, :string
      add :cover_image_url, :string
      add :cover_image_url_small, :string
      add :spotify_track_url, :string
      add :spotify_artist_url, :string
      add :spotify_album_url, :string
      add :duration_ms, :integer
      add :preview_url, :string
      add :comment_count, :integer, null: false, default: 0
      add :listens_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:songs, [:spotify_track_id])
  end
end
