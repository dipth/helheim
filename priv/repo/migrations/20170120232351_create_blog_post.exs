defmodule Helheim.Repo.Migrations.CreateBlogPost do
  use Ecto.Migration

  def change do
    create table(:blog_posts) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :title, :string, null: false
      add :body, :text, null: false

      timestamps()
    end

    create index(:blog_posts, [:user_id])
  end
end
