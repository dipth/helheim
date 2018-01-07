defmodule Helheim.Repo.Migrations.AddVisibilityToBlogPost do
  use Ecto.Migration

  def change do
    alter table(:blog_posts) do
      add :visibility, :text, null: false, default: "public"
    end

    create index(:blog_posts, [:visibility])
  end
end
