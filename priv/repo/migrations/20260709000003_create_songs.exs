defmodule Helheim.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :title, :string, null: false
      add :artist_name, :string, null: false
      add :album_name, :string
      add :cover_image_url, :string
      add :cover_image_url_small, :string
      add :lastfm_track_url, :string
      add :comment_count, :integer, null: false, default: 0
      add :listens_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:songs, ["lower(artist_name)", "lower(title)"], name: :songs_artist_title_index)
  end
end
