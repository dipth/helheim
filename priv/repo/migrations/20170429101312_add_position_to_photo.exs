defmodule Helheim.Repo.Migrations.AddPositionToPhoto do
  use Ecto.Migration

  def change do
    alter table(:photos) do
      add :position, :integer, default: 0, null: false
    end

    create index(:photos, [:photo_album_id, :position])
  end
end
