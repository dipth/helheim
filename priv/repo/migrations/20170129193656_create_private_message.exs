defmodule Helheim.Repo.Migrations.CreatePrivateMessage do
  use Ecto.Migration

  def change do
    create table(:private_messages) do
      add :conversation_id, :string, null: false
      add :sender_id, references(:users, on_delete: :nilify_all)
      add :recipient_id, references(:users, on_delete: :nilify_all)
      add :body, :text, null: false
      timestamps()
    end

    create index(:private_messages, [:conversation_id])
    create index(:private_messages, [:sender_id])
    create index(:private_messages, [:recipient_id])
  end
end
