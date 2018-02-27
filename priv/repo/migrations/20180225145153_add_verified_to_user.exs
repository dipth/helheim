defmodule Helheim.Repo.Migrations.AddVerifiedToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :verified_at, :utc_datetime
      add :verifier_id, references(:users, on_delete: :nilify_all)
    end

    create index(:users, [:verified_at])
    create index(:users, [:verifier_id])
  end
end
