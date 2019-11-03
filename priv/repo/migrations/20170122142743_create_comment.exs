defmodule Helheim.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      timestamps()
      add :deleted_at, :utc_datetime_usec
      add :approved_at, :utc_datetime_usec
      add :author_id, references(:users, on_delete: :delete_all)
      add :body, :text, null: false
      add :profile_id, references(:users, on_delete: :delete_all)
      add :blog_post_id, references(:blog_posts, on_delete: :delete_all)
    end

    create index(:comments, [:author_id])
    create index(:comments, [:profile_id])
    create index(:comments, [:blog_post_id])
    create index(:comments, [:inserted_at])
  end
end
