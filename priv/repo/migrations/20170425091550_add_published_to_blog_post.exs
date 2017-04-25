defmodule Helheim.Repo.Migrations.AddPublishedToBlogPost do
  use Ecto.Migration

  def up do
    alter table(:blog_posts) do
      add :published,    :boolean, default: false, null: false
      add :published_at, :utc_datetime
    end

    create index(:blog_posts, [:published])
    create index(:blog_posts, [:published_at])

    execute "UPDATE blog_posts SET published = TRUE, published_at = inserted_at"
  end

  def down do
    drop index(:blog_posts, [:published])
    drop index(:blog_posts, [:published_at])

    alter table(:blog_posts) do
      remove :published
      remove :published_at
    end
  end
end
