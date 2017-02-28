defmodule Helheim.Repo.Migrations.AddVisitorCount do
  use Ecto.Migration

  def change do
    alter table(:blog_posts) do
      add :visitor_count, :integer, null: false, default: 0
    end
    alter table(:photo_albums) do
      add :visitor_count, :integer, null: false, default: 0
    end
    alter table(:photos) do
      add :visitor_count, :integer, null: false, default: 0
    end
    alter table(:users) do
      add :visitor_count, :integer, null: false, default: 0
    end
  end
end
