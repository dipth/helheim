defmodule Helheim.LastfmAccount do
  use Helheim, :model

  alias Helheim.LastfmAccount
  alias Helheim.Repo
  alias Helheim.User

  schema "lastfm_accounts" do
    belongs_to :user, User
    field :username,            :string
    field :session_key,         :string
    field :broken_at,           :utc_datetime_usec
    field :last_polled_at,      :utc_datetime_usec
    field :played_after_cursor, :integer
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :session_key, :broken_at, :last_polled_at, :played_after_cursor])
    |> validate_required([:username, :session_key])
    |> unique_constraint(:user_id)
  end

  def not_broken(query) do
    from a in query, where: is_nil(a.broken_at)
  end

  def get_for_user(user) do
    Repo.get_by(LastfmAccount, user_id: user.id)
  end
end
