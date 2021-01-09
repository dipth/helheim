defmodule Helheim.Repo.Migrations.AddSpotifyToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :spotify_access_token, :string
      add :spotify_refresh_token, :string
    end
  end
end
