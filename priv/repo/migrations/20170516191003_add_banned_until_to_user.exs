defmodule Helheim.Repo.Migrations.AddBannedUntilToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :banned_until, :utc_datetime
      add :ban_reason,   :text
    end
  end
end
