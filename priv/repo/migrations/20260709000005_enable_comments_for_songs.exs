defmodule Helheim.Repo.Migrations.EnableCommentsForSongs do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add :song_id, references(:songs, on_delete: :delete_all)
    end
    create index(:comments, [:song_id])

    alter table(:notification_subscriptions) do
      add :song_id, references(:songs, on_delete: :delete_all)
    end
    create index(:notification_subscriptions, [:song_id])

    alter table(:notifications) do
      add :song_id, references(:songs, on_delete: :delete_all)
    end
    create index(:notifications, [:song_id])
  end
end
