defmodule Helheim.Repo.Migrations.AddIncognitoToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :incognito, :boolean, default: false
    end
  end
end
