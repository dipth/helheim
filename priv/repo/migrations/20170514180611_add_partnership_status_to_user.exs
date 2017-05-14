defmodule Helheim.Repo.Migrations.AddPartnershipStatusToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :partnership_status, :string
    end
  end
end
