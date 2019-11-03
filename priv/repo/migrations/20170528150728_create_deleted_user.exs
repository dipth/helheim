defmodule Helheim.Repo.Migrations.CreateDeletedUser do
  use Ecto.Migration

  def change do
    create table(:deleted_users, primary_key: false) do
      add :id,                   :uuid,         primary_key: true
      add :original_id,          :integer,      null: false
      add :username,             :string,       null: false
      add :email,                :string,       null: false
      add :name,                 :string,       null: false
      add :banned_until,         :utc_datetime_usec
      add :ban_reason,           :text
      add :confirmed_at,         :utc_datetime_usec
      add :last_login_at,        :utc_datetime_usec
      add :previous_login_at,    :utc_datetime_usec
      add :last_login_ip,        :string
      add :previous_login_ip,    :string
      add :original_inserted_at, :utc_datetime_usec, null: false
      add :original_updated_at,  :utc_datetime_usec
      timestamps()
    end

    create index(:deleted_users, [:original_id])
    create index(:deleted_users, [:username])
    create index(:deleted_users, [:email])
  end
end
