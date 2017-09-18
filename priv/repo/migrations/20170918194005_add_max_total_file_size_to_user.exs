defmodule Helheim.Repo.Migrations.AddMaxTotalFileSizeToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Default: 25 MB
      add :max_total_file_size, :integer, default: (25 * 1024 * 1024), null: false
    end
  end
end
