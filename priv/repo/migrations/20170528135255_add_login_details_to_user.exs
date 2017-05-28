defmodule Helheim.Repo.Migrations.AddLoginDetailsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_login_at,     :utc_datetime
      add :previous_login_at, :utc_datetime
      add :last_login_ip,     :string
      add :previous_login_ip, :string
    end
  end
end
