defmodule Helheim.Repo.Migrations.AddNoticeToForumReply do
  use Ecto.Migration

  def change do
    alter table(:forum_replies) do
      add :notice, :boolean, default: false, null: false
    end

    create index(:forum_replies, [:notice])
  end
end
