defmodule Helheim.Repo.Migrations.CreateTerm do
  use Ecto.Migration

  def change do
    create table(:terms) do
      add :body,      :text,    null: false
      add :published, :boolean, null: false, default: false
      timestamps()
    end

    create index(:terms, [:published])
  end
end
