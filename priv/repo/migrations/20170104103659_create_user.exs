defmodule Altnation.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name,               :string, null: false
      add :email,              :string, null: false
      add :username,           :string, null: false
      add :password_hash,      :string, null: false
      add :confirmation_token, :string, null: false
      add :confirmed_at,       :utc_datetime

      timestamps()
    end
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:confirmation_token])
  end
end
