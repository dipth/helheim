defmodule Altnation.User do
  use Altnation.Web, :model
  alias Altnation.Repo

  schema "users" do
    field :name,                            :string
    field :email,                           :string
    field :username,                        :string
    field :password,                        :string, virtual: true
    field :password_hash,                   :string
    field :password_reset_token,            :string
    field :password_reset_token_updated_at, Calecto.DateTimeUTC
    field :confirmation_token,              :string
    field :confirmed_at,                    Calecto.DateTimeUTC

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :username, :password])
    |> validate_required([:name, :email, :username])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> put_password_hash()
    |> put_confirmation_token()
  end

  def new_password_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> put_password_hash()
    |> clear_password_reset_token()
  end

  def confirm!(user) do
    case user.confirmed_at do
      nil ->
        changeset = Ecto.Changeset.change user, confirmed_at: DateTime.utc_now
        Repo.update(changeset)
      _ -> {:ok, user}
    end
  end

  def confirmed?(user) do
    !is_nil(user.confirmed_at)
  end

  def update_password_reset_token!(user) do
    changeset = Ecto.Changeset.change user,
      password_reset_token: SecureRandom.urlsafe_base64(16),
      password_reset_token_updated_at: DateTime.utc_now
    Repo.update(changeset)
  end

  def password_reset_token_expired?(user) do
    user.password_reset_token_updated_at < Calendar.DateTime.subtract!(DateTime.utc_now, 24 * 60 * 60)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end

  defp put_confirmation_token(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        put_change(changeset, :confirmation_token, SecureRandom.urlsafe_base64(16))
      _ ->
        changeset
    end
  end

  defp clear_password_reset_token(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        put_change(changeset, :password_reset_token, nil)
      _ ->
        changeset
    end
  end
end
