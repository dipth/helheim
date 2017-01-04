defmodule Altnation.User do
  use Altnation.Web, :model
  alias Altnation.Repo

  schema "users" do
    field :name,               :string
    field :email,              :string
    field :username,           :string
    field :password,           :string, virtual: true
    field :password_hash,      :string
    field :confirmation_token, :string
    field :confirmed_at,       Calecto.DateTimeUTC

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

  def confirm!(user) do
    case user.confirmed_at do
      nil ->
        changeset = Ecto.Changeset.change user, confirmed_at: DateTime.utc_now
        Repo.update(changeset)
      _ -> {:ok, user}
    end
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
end
