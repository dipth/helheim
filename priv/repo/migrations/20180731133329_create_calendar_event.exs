defmodule Helheim.Repo.Migrations.CreateCalendarEvent do
  use Ecto.Migration

  def change do
    create table(:calendar_events) do
      add :user_id,     references(:users, on_delete: :nilify_all)
      add :uuid,        :string,        null: false
      add :title,       :string,        null: false
      add :description, :text,          null: false
      add :starts_at,   :utc_datetime,  null: false
      add :ends_at,     :utc_datetime,  null: false
      add :location,    :string,        null: false
      add :url,         :string
      add :image,       :string
      add :approved_at, :utc_datetime
      add :rejected_at, :utc_datetime

      timestamps()
    end

    create unique_index(:calendar_events, [:uuid])
    create index(:calendar_events, [:user_id])
    create index(:calendar_events, [:approved_at])
    create index(:calendar_events, [:ends_at])
  end
end
