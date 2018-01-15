defmodule Helheim.Repo.Migrations.AddHideCommentsToBlogPost do
  use Ecto.Migration

  def change do
    alter table(:blog_posts) do
      add :hide_comments, :boolean, null: false, default: false
    end
  end
end
