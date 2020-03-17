defmodule Helheim.Repo.Migrations.AddModMessageToBlogPost do
  use Ecto.Migration

  def change do
    alter table(:blog_posts) do
      add :mod_message, :text
    end
  end
end
