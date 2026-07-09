defmodule Helheim.Repo.Migrations.CreateSpotifyAccounts do
  use Ecto.Migration

  def change do
    create table(:spotify_accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :spotify_user_id, :string
      add :access_token, :text, null: false
      add :refresh_token, :text, null: false
      add :token_expires_at, :utc_datetime_usec, null: false
      add :scopes, :string
      add :broken_at, :utc_datetime_usec
      add :last_polled_at, :utc_datetime_usec
      add :played_after_cursor, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:spotify_accounts, [:user_id])
  end
end
