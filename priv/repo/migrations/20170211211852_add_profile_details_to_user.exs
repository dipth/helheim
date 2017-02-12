defmodule Helheim.Repo.Migrations.AddProfileDetailsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :gender, :string
      add :location, :string
    end

    create index(:users, [:gender])
  end
end
