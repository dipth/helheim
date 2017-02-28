defmodule Helheim.Repo.Migrations.CreateVisitorLogEntry do
  use Ecto.Migration

  def change do
    create table(:visitor_log_entries) do
      timestamps()
      add :user_id,        references(:users,        on_delete: :nilify_all)
      add :blog_post_id,   references(:blog_posts,   on_delete: :delete_all)
      add :photo_album_id, references(:photo_albums, on_delete: :delete_all)
      add :photo_id,       references(:photos,       on_delete: :delete_all)
      add :profile_id,     references(:users,        on_delete: :delete_all)
    end

    create index(:visitor_log_entries, [:user_id])
    create index(:visitor_log_entries, [:blog_post_id])
    unique_index(:visitor_log_entries, [:user_id, :blog_post_id])
    create index(:visitor_log_entries, [:photo_album_id])
    unique_index(:visitor_log_entries, [:user_id, :photo_album_id])
    create index(:visitor_log_entries, [:photo_id])
    unique_index(:visitor_log_entries, [:user_id, :photo_id])
    create index(:visitor_log_entries, [:profile_id])
    unique_index(:visitor_log_entries, [:user_id, :profile_id])
  end
end
