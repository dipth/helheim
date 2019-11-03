defmodule Helheim.Repo.Migrations.CreateForumTables do
  use Ecto.Migration

  def change do
    create table(:forum_categories) do
      add :title,       :string,  null: false
      add :description, :text
      add :rank,        :integer, null: false, default: 0
      timestamps()
    end

    create table(:forums) do
      add :forum_category_id, references(:forum_categories, on_delete: :delete_all)
      add :title,              :string,  null: false
      add :description,        :text
      add :rank,               :integer, null: false, default: 0
      add :forum_topics_count, :integer, null: false, default: 0
      timestamps()
    end
    create index(:forums, [:forum_category_id])

    create table(:forum_topics) do
      add :forum_id,            references(:forums, on_delete: :nilify_all)
      add :user_id,             references(:users,  on_delete: :nilify_all)
      add :title,               :string,  null: false
      add :body,                :text,    null: false
      add :pinned,              :boolean, null: false, default: false
      add :forum_replies_count, :integer, null: false, default: 0
      add :deleted_at,          :utc_datetime_usec
      timestamps()
    end
    create index(:forum_topics, [:forum_id])
    create index(:forum_topics, [:user_id])
    create index(:forum_topics, [:deleted_at])

    create table(:forum_replies) do
      add :forum_topic_id, references(:forum_topics, on_delete: :delete_all)
      add :user_id,        references(:users,        on_delete: :nilify_all)
      add :body,           :text, null: false
      add :deleted_at,     :utc_datetime_usec
      timestamps()
    end
    create index(:forum_replies, [:forum_topic_id])
    create index(:forum_replies, [:user_id])
    create index(:forum_replies, [:deleted_at])
  end
end
