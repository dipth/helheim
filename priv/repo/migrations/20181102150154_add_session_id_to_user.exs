defmodule Helheim.Repo.Migrations.AddSessionIdToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :session_id, :string
    end

    create index(:users, [:session_id])
  end
end
