defmodule Helheim.DeletedUser do
  use Helheim.Web, :model
  use Arc.Ecto.Schema
  use Timex
  alias Helheim.Repo
  alias Helheim.DeletedUser

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "deleted_users" do
    field :original_id,          :integer
    field :username,             :string
    field :email,                :string
    field :name,                 :string
    field :banned_until,         Calecto.DateTimeUTC
    field :ban_reason,           :string
    field :confirmed_at,         Calecto.DateTimeUTC
    field :last_login_at,        Calecto.DateTimeUTC
    field :last_login_ip,        :string
    field :previous_login_at,    Calecto.DateTimeUTC
    field :previous_login_ip,    :string
    field :original_inserted_at, Calecto.DateTimeUTC
    field :original_updated_at,  Calecto.DateTimeUTC

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :original_id, :username, :email, :name, :banned_until, :ban_reason,
      :confirmed_at, :last_login_at, :last_login_ip, :previous_login_at,
      :previous_login_ip, :original_inserted_at, :original_updated_at])
    |> validate_required([:original_id, :username, :email, :name, :original_inserted_at])
  end

  def track_deletion!(user) do
    params = %{
      original_id:          user.id,
      username:             user.username,
      email:                user.email,
      name:                 user.name,
      banned_until:         user.banned_until,
      ban_reason:           user.ban_reason,
      confirmed_at:         user.confirmed_at,
      last_login_at:        user.last_login_at,
      last_login_ip:        user.last_login_ip,
      previous_login_at:    user.previous_login_at,
      previous_login_ip:    user.previous_login_ip,
      original_inserted_at: user.inserted_at,
      original_updated_at:  user.updated_at
    }
    DeletedUser.changeset(%DeletedUser{}, params)
    |> Repo.insert()
  end
end
