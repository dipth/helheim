defmodule Helheim.Repo.Migrations.ChangeCommentAuthorToNilify do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE comments DROP CONSTRAINT comments_author_id_fkey"
    alter table(:comments) do
      modify :author_id, references(:users, on_delete: :nilify_all)
    end
  end

  def down do
    execute "ALTER TABLE comments DROP CONSTRAINT comments_author_id_fkey"
    alter table(:comments) do
      modify :author_id, references(:users, on_delete: :delete_all)
    end
  end
end
