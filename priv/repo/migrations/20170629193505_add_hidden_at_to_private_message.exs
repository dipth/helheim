defmodule Helheim.Repo.Migrations.AddHiddenAtToPrivateMessage do
  use Ecto.Migration

  def change do
    alter table(:private_messages) do
      add :hidden_by_sender_at, :utc_datetime_usec
      add :hidden_by_recipient_at, :utc_datetime_usec
    end

    create index(:private_messages, [:hidden_by_sender_at])
    create index(:private_messages, [:hidden_by_recipient_at])
  end
end
