defmodule Helheim.User do
  use Helheim.Web, :model
  use Arc.Ecto.Schema
  use Timex
  alias Helheim.Repo
  import Helheim.Gettext

  schema "users" do
    field :name,                            :string
    field :email,                           :string
    field :username,                        :string
    field :password,                        :string, virtual: true
    field :password_confirmation,           :string, virtual: true
    field :existing_password,               :string, virtual: true
    field :password_hash,                   :string
    field :password_reset_token,            :string
    field :password_reset_token_updated_at, Calecto.DateTimeUTC
    field :confirmation_token,              :string
    field :confirmed_at,                    Calecto.DateTimeUTC
    field :avatar,                          Helheim.Avatar.Type
    field :profile_text,                    :string
    field :role,                            :string
    field :gender,                          :string
    field :gender_custom,                   :string, virtual: true
    field :location,                        :string

    has_many :blog_posts, Helheim.BlogPost
    has_many :comments, Helheim.Comment, foreign_key: :profile_id
    has_many :authored_comments, Helheim.Comment, foreign_key: :author_id
    has_many :notifications, Helheim.Notification
    has_many :sent_private_messages, Helheim.PrivateMessage, foreign_key: :sender_id
    has_many :received_private_messages, Helheim.PrivateMessage, foreign_key: :recipient_id
    has_many :photo_albums, Helheim.PhotoAlbum

    timestamps()
  end

  def newest(query) do
    from u in query,
    order_by: [desc: u.inserted_at]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :username, :password, :password_confirmation])
    |> trim_fields([:name, :email, :username])
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
    |> validate_confirmation(:password)
    |> put_password_hash()
    |> reset_confirmed_state_if_email_changed()
  end

  def new_password_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> put_password_hash()
    |> clear_password_reset_token()
  end

  def account_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :password, :password_confirmation, :existing_password])
    |> trim_fields([:name, :email])
    |> validate_required([:name, :email, :existing_password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> validate_existing_password()
    |> unique_constraint(:email)
    |> put_password_hash()
    |> reset_confirmed_state_if_email_changed()
  end

  def profile_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:gender, :gender_custom, :location, :profile_text])
    |> allow_custom_value_for_fields([{:gender, :gender_custom}])
    |> trim_fields([:gender, :location])
    |> cast_attachments(params, [:avatar])
    |> validate_required([:profile_text])
    |> scrub_profile_text()
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
    Timex.before?(user.password_reset_token_updated_at, Timex.shift(Timex.now, days: -1))
  end

  def admin?(user) do
    user.role == "admin"
  end

  def delete!(user) do
    photo_albums = assoc(user, :photo_albums) |> Repo.all
    Parallel.pmap(photo_albums, fn(pa) -> Helheim.PhotoAlbum.delete!(pa) end)
    Repo.delete!(user)
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
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

  defp validate_existing_password(changeset) do
    case changeset do
      %Ecto.Changeset{changes: %{existing_password: existing_password}} ->
        password_hash = get_field(changeset, :password_hash)
        if Helheim.Auth.password_correct?(password_hash, existing_password) do
          changeset
        else
          add_error(changeset, :existing_password, gettext("does not match your current password"))
        end
      _ ->
        changeset
    end
  end

  defp reset_confirmed_state_if_email_changed(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{email: email}} ->
        changeset = put_change(changeset, :confirmation_token, SecureRandom.urlsafe_base64(16))
        changeset = put_change(changeset, :confirmed_at, nil)
        confirmation_token = get_field(changeset, :confirmation_token)
        Helheim.Email.registration_email(email, confirmation_token) |> Helheim.Mailer.deliver_later
        changeset
      _ ->
        changeset
    end
  end

  defp scrub_profile_text(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{profile_text: profile_text}} ->
        put_change(changeset, :profile_text, profile_text |> HtmlSanitizeEx.Scrubber.scrub(Helheim.Scrubber))
      _ ->
        changeset
    end
  end
end
