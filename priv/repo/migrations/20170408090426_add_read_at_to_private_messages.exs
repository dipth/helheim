defmodule Helheim.Repo.Migrations.AddReadAtToPrivateMessages do
  use Ecto.Migration

  def change do
    alter table(:private_messages) do
      add :read_at, :utc_datetime_usec
    end
    create index(:private_messages, [:read_at])
  end
end
