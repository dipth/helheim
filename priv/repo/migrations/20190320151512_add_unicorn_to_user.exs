defmodule Helheim.Repo.Migrations.AddUnicornToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :unicorn_at, :utc_datetime
    end

    create index(:users, [:unicorn_at])
  end
end
