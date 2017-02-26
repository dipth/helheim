defmodule Helheim.Repo.Migrations.AddLockedToForum do
  use Ecto.Migration

  def change do
    alter table(:forums) do
      add :locked, :boolean, null: false, default: false
    end
  end
end
