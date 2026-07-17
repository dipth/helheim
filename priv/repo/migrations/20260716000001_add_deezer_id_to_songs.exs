defmodule Helheim.Repo.Migrations.AddDeezerIdToSongs do
  use Ecto.Migration

  def change do
    alter table(:songs) do
      add :deezer_id, :bigint
    end
  end
end
