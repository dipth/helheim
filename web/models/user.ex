defmodule Helheim.User do
  use Helheim.Web, :model
  use Arc.Ecto.Schema
  use Timex
  alias Helheim.Repo
  alias Helheim.User
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
    field :partnership_status,              :string
    field :partnership_status_custom,       :string, virtual: true
    field :birthday,                        :date
    field :banned_until,                    Calecto.DateTimeUTC
    field :ban_reason,                      :string
    field :visitor_count,                   :integer
    field :comment_count,                   :integer
    field :last_login_at,                   Calecto.DateTimeUTC
    field :last_login_ip,                   :string
    field :previous_login_at,               Calecto.DateTimeUTC
    field :previous_login_ip,               :string
    field :max_total_file_size,             :integer
    field :last_donation_at,                Calecto.DateTimeUTC
    field :total_donated,                   :integer
    field :captcha,                         :string, virtual: true

    timestamps()

    has_many :blog_posts,                Helheim.BlogPost
    has_many :comments,                  Helheim.Comment,        foreign_key: :profile_id
    has_many :authored_comments,         Helheim.Comment,        foreign_key: :author_id
    has_many :notifications,             Helheim.Notification,   foreign_key: :recipient_id
    has_many :sent_private_messages,     Helheim.PrivateMessage, foreign_key: :sender_id
    has_many :received_private_messages, Helheim.PrivateMessage, foreign_key: :recipient_id
    has_many :photo_albums,              Helheim.PhotoAlbum
    has_many :visitor_log_entries,       Helheim.VisitorLogEntry, foreign_key: :profile_id
    has_many :donations,                 Helheim.Donation
  end

  def newest(query) do
    from u in query,
    order_by: [desc: u.inserted_at]
  end

  def recently_logged_in(query) do
    from u in query,
    where: not is_nil(u.last_login_at),
    order_by: [desc: u.last_login_at]
  end

  def with_avatar(query) do
    from u in query, where: not is_nil(u.avatar)
  end

  def confirmed(query) do
    from u in query, where: not is_nil(u.confirmed_at)
  end

  def search(query, search_params) do
    query
    |> search_by_username(search_params["username"])
    |> search_by_location(search_params["location"])
  end

  def search_by_username(query, nil), do: query
  def search_by_username(query, ""), do: query
  def search_by_username(query, username) do
    from u in query, where: ilike(u.username, ^"%#{username}%")
  end

  def search_by_location(query, nil), do: query
  def search_by_location(query, ""), do: query
  def search_by_location(query, location) do
    from u in query, where: ilike(u.location, ^"%#{location}%")
  end

  def sort(query, nil), do: query
  def sort(query, "creation") do
    from u in query, order_by: [desc: u.inserted_at]
  end
  def sort(query, "login") do
    from u in query, order_by: [fragment("? DESC NULLS LAST", u.last_login_at)]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :username, :password, :password_confirmation, :captcha])
    |> trim_fields([:name, :email, :username])
    |> validate_required([:name, :email, :username])
    |> validate_format(:email, ~r/@/)
    |> validate_format(:username, ~r/\A[\w\-\.\x{00C0}-\x{017F}]+\z/u)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> validate_required([:password, :captcha])
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> validate_captcha(:captcha)
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
    |> cast(params, [:gender, :gender_custom, :location, :partnership_status, :partnership_status_custom, :profile_text, :birthday])
    |> allow_custom_value_for_fields([{:gender, :gender_custom}, {:partnership_status, :partnership_status_custom}])
    |> trim_fields([:gender, :location, :partnership_status])
    |> cast_attachments(params, [:avatar])
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

  def admin?(%User{role: "admin"}), do: true
  def admin?(_), do: false

  def moderator?(%User{role: "moderator"}), do: true
  def moderator?(_), do: false

  def delete!(user) do
    photo_albums = assoc(user, :photo_albums) |> Repo.all
    Parallel.pmap(photo_albums, fn(pa) -> Helheim.PhotoAlbum.delete!(pa) end)
    Repo.delete!(user)
  end

  def age(user, now) do
    birthday = user.birthday

    if now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day) do
      now.year - birthday.year - 1
    else
      now.year - birthday.year
    end
  end

  def banned?(%{banned_until: nil}), do: false
  def banned?(user) do
    Timex.after?(user.banned_until, Timex.now)
  end

  def track_login!(nil, _), do: {:ok, nil}
  def track_login!(user, ip_addr) do
    changeset = Ecto.Changeset.change user,
      previous_login_at: user.last_login_at,
      previous_login_ip: user.last_login_ip,
      last_login_at:     DateTime.utc_now,
      last_login_ip:     ip_addr
    Repo.update(changeset)
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

  defp validate_captcha(changeset, field, options \\ []) do
    validate_change changeset, field, fn _, captcha ->
      case Recaptcha.verify(captcha) do
        {:ok, _} -> []
        {:error, _} -> [{field, options[:message] || gettext("I too enjoy registering on websites, fellow human... Bleep Bloop!")}]
      end
    end
  end
end
