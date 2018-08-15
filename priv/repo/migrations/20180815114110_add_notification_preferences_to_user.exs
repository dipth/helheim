defmodule Helheim.Repo.Migrations.AddNotificationPreferencesToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notification_sound, :string
      add :mute_notifications, :boolean
    end
  end
end
