defmodule Helheim.Repo.Migrations.CreateDonation do
  use Ecto.Migration

  def change do
    create table(:donations) do
      add :user_id,     references(:users, on_delete: :nilify_all)
      add :token,       :string,  null: false
      add :amount,      :integer, null: false, default: 0
      add :charge,      :jsonb
      add :fee,         :integer
      add :balance_txn, :jsonb
      timestamps()
    end

    create index(:donations, [:user_id])
    create unique_index(:donations, [:token])
  end
end
