defmodule Helheim.Repo.Migrations.CreateFriendship do
  use Ecto.Migration

  def up do
    create table(:friendships) do
      add :sender_id, references(:users, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
      add :accepted_at, :utc_datetime_usec
    end

    create index(:friendships, [:sender_id])
    create index(:friendships, [:recipient_id])
    execute """
      CREATE UNIQUE INDEX friendships_users_index ON friendships(
        GREATEST(sender_id,recipient_id), LEAST(sender_id,recipient_id)
      )
    """
  end

  def down do
    drop table(:friendships)
  end
end
