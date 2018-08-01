defmodule Helheim.Repo.Migrations.ChangeUsersMaxTotalFileSizeToBigInt do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :max_total_file_size, :bigint
    end
  end

  def down do
    alter table(:users) do
      modify :max_total_file_size, :integer
    end
  end
end
