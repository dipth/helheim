defmodule Helheim.Repo.Migrations.CreateSongUpvotes do
  use Ecto.Migration

  def change do
    create table(:song_upvotes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :song_id, references(:songs, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:song_upvotes, [:user_id, :song_id])
    create index(:song_upvotes, [:song_id])
    # Serves the rolling-window charts, which filter on inserted_at and then
    # group by song; leading with inserted_at keeps the range scan tight and
    # including song_id lets it satisfy the join without heap fetches.
    create index(:song_upvotes, [:inserted_at, :song_id])

    alter table(:songs) do
      add :upvotes_count, :integer, null: false, default: 0
    end
  end
end
