defmodule Helheim.Repo.Migrations.AddCommentCountsAndMoreCommentables do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :photo_album_id, references(:photo_albums, on_delete: :delete_all)
      add :photo_id,       references(:photos, on_delete: :delete_all)
    end

    create index(:comments, [:photo_album_id])
    create index(:comments, [:photo_id])

    alter table(:blog_posts) do
      add :comment_count, :integer, null: false, default: 0
    end
    alter table(:photo_albums) do
      add :comment_count, :integer, null: false, default: 0
    end
    alter table(:photos) do
      add :comment_count, :integer, null: false, default: 0
    end
    alter table(:users) do
      add :comment_count, :integer, null: false, default: 0
    end
  end
end
