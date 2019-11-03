defmodule Helheim.Repo.Migrations.CreateNotification do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :title, :string, null: false
      add :icon, :string
      add :path, :string
      add :read_at, :utc_datetime_usec
      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:read_at])
  end
end
