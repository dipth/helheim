defmodule Helheim.Repo.Migrations.MakeUsersEmailAndUsernameCaseInsensitive do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;")
    drop unique_index(:users, [:email])
    drop unique_index(:users, [:username])
    alter table(:users) do
      modify :email, :citext, null: false
      modify :username, :citext, null: false
    end
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end

  def down do
    drop unique_index(:users, [:email])
    drop unique_index(:users, [:username])
    alter table(:users) do
      modify :email, :string, null: false
      modify :username, :string, null: false
    end
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    execute("DROP EXTENSION IF EXISTS citext;")
  end
end
