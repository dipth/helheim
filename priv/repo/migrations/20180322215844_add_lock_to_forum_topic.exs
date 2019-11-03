defmodule Helheim.Repo.Migrations.AddLockToForumTopic do
  use Ecto.Migration

  def change do
    alter table(:forum_topics) do
      add :locked_at, :utc_datetime_usec
    end

    create index(:forum_topics, [:locked_at])
  end
end
