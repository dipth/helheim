defmodule Helheim.Repo.Migrations.CreateNotificationSubscription do
  use Ecto.Migration

  def change do
    create table(:notification_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type,    :string,  null: false
      add :enabled, :boolean, null: false, default: false
      timestamps()
      add :profile_id,     references(:users,        on_delete: :delete_all)
      add :blog_post_id,   references(:blog_posts,   on_delete: :delete_all)
      add :photo_album_id, references(:photo_albums, on_delete: :delete_all)
      add :photo_id,       references(:photos,       on_delete: :delete_all)
      add :forum_topic_id, references(:forum_topics, on_delete: :delete_all)
    end

    create index(:notification_subscriptions, [:user_id])
    unique_index(:notification_subscriptions, [:user_id, :type, :profile_id, :blog_post_id, :photo_album_id, :photo_id, :forum_topic_id])
  end
end
