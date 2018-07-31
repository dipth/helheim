defmodule Helheim.Repo.Migrations.EnableCommentsForCalendarEvents do
  use Ecto.Migration

  def change do
    alter table(:calendar_events) do
      add :comment_count, :integer, null: false, default: 0
    end

    alter table(:comments) do
      add :calendar_event_id, references(:calendar_events, on_delete: :delete_all)
    end
    create index(:comments, [:calendar_event_id])

    alter table(:notification_subscriptions) do
      add :calendar_event_id, references(:calendar_events, on_delete: :delete_all)
    end
    create index(:notification_subscriptions, [:calendar_event_id])

    alter table(:notifications) do
      add :calendar_event_id, references(:calendar_events, on_delete: :delete_all)
    end
    create index(:notifications, [:calendar_event_id])
  end
end
