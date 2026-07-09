defmodule Helheim.Repo.Migrations.CreateSongListens do
  use Ecto.Migration

  def change do
    create table(:song_listens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :song_id, references(:songs, on_delete: :delete_all), null: false
      add :played_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:song_listens, [:user_id, :played_at])
    create index(:song_listens, [:song_id])
    create index(:song_listens, [:user_id, :song_id])
    create index(:song_listens, [:played_at])
  end
end
