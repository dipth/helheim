defmodule Helheim.SpotifyAccount do
  use Helheim, :model

  alias Helheim.User

  schema "spotify_accounts" do
    belongs_to :user, User
    field :spotify_user_id,     :string
    field :access_token,        :string
    field :refresh_token,       :string
    field :token_expires_at,    :utc_datetime_usec
    field :scopes,              :string
    field :broken_at,           :utc_datetime_usec
    field :last_polled_at,      :utc_datetime_usec
    field :played_after_cursor, :integer
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:spotify_user_id, :access_token, :refresh_token, :token_expires_at, :scopes, :broken_at, :last_polled_at, :played_after_cursor])
    |> validate_required([:access_token, :refresh_token, :token_expires_at])
  end

  def not_broken(query) do
    from a in query, where: is_nil(a.broken_at)
  end

  def token_expires_within?(account, seconds) do
    DateTime.compare(account.token_expires_at, DateTime.add(DateTime.utc_now(), seconds, :second)) == :lt
  end
end
