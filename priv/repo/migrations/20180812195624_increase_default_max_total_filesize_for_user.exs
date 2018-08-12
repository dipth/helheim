defmodule Helheim.Repo.Migrations.IncreaseDefaultMaxTotalFilesizeForUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      # 1 GB
      modify :max_total_file_size, :bigint, default: (1024 * 1024 * 1024), null: false
    end
  end

  def down do
    alter table(:users) do
      # 25 MB
      modify :max_total_file_size, :bigint, default: (25 * 1024 * 1024), null: false
    end
  end
end
