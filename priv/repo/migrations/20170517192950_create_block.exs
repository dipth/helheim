defmodule Helheim.Repo.Migrations.CreateBlock do
  use Ecto.Migration

  def change do
    create table(:blocks) do
      add :blocker_id, references(:users, on_delete: :delete_all), null: false
      add :blockee_id, references(:users, on_delete: :delete_all), null: false
      add :enabled,    :boolean, default: false, null: false
      timestamps()
    end

    create index(:blocks, [:blocker_id])
    create index(:blocks, [:blockee_id])
    create unique_index(:blocks, [:blocker_id, :blockee_id])
  end
end
