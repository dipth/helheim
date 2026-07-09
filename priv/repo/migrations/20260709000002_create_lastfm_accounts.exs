defmodule Helheim.Repo.Migrations.CreateLastfmAccounts do
  use Ecto.Migration

  def change do
    create table(:lastfm_accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :username, :string, null: false
      add :session_key, :text, null: false
      add :broken_at, :utc_datetime_usec
      add :last_polled_at, :utc_datetime_usec
      add :played_after_cursor, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lastfm_accounts, [:user_id])
  end
end
