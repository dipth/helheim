defmodule Helheim.Repo.Migrations.AddDeletionColumnsToComment do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :deletion_reason, :text
      add :deleter_id,      references(:users, on_delete: :nilify_all)
    end

    create index(:comments, [:deleted_at])
  end
end
