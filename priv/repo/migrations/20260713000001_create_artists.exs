defmodule Helheim.Repo.Migrations.CreateArtists do
  use Ecto.Migration

  def change do
    create table(:artists) do
      add :name, :string, null: false
      add :mbid, :string
      add :country_code, :string
      add :country_name, :string
      add :image_url_small, :string
      add :image_url_medium, :string
      add :image_url_large, :string
      add :image_source, :string
      add :enriched_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:artists, ["lower(name)"], name: :artists_name_index)
  end
end
