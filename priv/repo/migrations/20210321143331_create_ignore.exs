defmodule Helheim.Repo.Migrations.CreateIgnore do
  use Ecto.Migration

  def change do
    create table(:ignores) do
      add :ignorer_id, references(:users, on_delete: :delete_all), null: false
      add :ignoree_id, references(:users, on_delete: :delete_all), null: false
      add :enabled,    :boolean, default: false, null: false
      timestamps()
    end

    create index(:ignores, [:ignorer_id])
    create index(:ignores, [:ignoree_id])
    create unique_index(:ignores, [:ignorer_id, :ignoree_id])
  end
end
