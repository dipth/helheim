defmodule Altnation.Repo.Migrations.AddProfileTextToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_text, :string
    end
  end
end
