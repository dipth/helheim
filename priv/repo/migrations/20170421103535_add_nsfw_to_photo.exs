defmodule Helheim.Repo.Migrations.AddNSFWToPhoto do
  use Ecto.Migration

  def change do
    alter table(:photos) do
      add :nsfw, :boolean, default: false, null: false
    end
  end
end
