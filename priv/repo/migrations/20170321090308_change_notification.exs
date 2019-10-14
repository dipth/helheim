defmodule Helheim.Repo.Migrations.ChangeNotification do
  use Ecto.Migration

  def up do
    drop table(:notifications)

    create table(:notifications, primary_key: false) do
      add :id,                :uuid, primary_key: true
      add :recipient_id,      references(:users, on_delete: :delete_all)
      add :trigger_person_id, references(:users, on_delete: :nilify_all)
      add :type,              :string, null: false
      timestamps()
      add :seen_at,           :utc_datetime_usec
      add :clicked_at,        :utc_datetime_usec
      add :profile_id,        references(:users,        on_delete: :delete_all)
      add :blog_post_id,      references(:blog_posts,   on_delete: :delete_all)
      add :photo_album_id,    references(:photo_albums, on_delete: :delete_all)
      add :photo_id,          references(:photos,       on_delete: :delete_all)
      add :forum_topic_id,    references(:forum_topics, on_delete: :delete_all)
    end

    create index(:notifications, [:recipient_id])
  end

  def down do
    drop table(:notifications)

    create table(:notifications) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :title, :string, null: false
      add :icon, :string
      add :path, :string
      add :read_at, :utc_datetime_usec
      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:read_at])
  end
end
