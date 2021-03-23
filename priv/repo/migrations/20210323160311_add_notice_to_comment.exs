defmodule Helheim.Repo.Migrations.AddNoticeToComment do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :notice, :boolean, default: false, null: false
    end

    create index(:comments, [:notice])
  end
end
