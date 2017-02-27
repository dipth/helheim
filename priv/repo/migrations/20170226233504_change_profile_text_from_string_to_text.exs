defmodule Helheim.Repo.Migrations.ChangeProfileTextFromStringToText do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :profile_text, :text
    end
  end

  def down do
    alter table(:users) do
      modify :profile_text, :string
    end
  end
end
