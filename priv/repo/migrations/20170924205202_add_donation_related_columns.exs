defmodule Helheim.Repo.Migrations.AddDonationRelatedColumns do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_donation_at, :utc_datetime_usec
      add :total_donated,    :integer, null: false, default: 0
    end

    create index(:users, [:last_donation_at])
    create index(:users, [:total_donated])
  end
end
