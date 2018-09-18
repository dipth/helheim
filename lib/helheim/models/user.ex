defmodule Helheim.User do
  use Helheim, :model

  use Arc.Ecto.Schema
  use Timex
  alias Helheim.Repo
  alias Helheim.User
  import HelheimWeb.Gettext

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
    field :avatar,                          HelheimWeb.Avatar.Type
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
    field :verified_at,                     Calecto.DateTimeUTC
    field :notification_sound,              :string
    field :mute_notifications,              :boolean

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
    has_many :forum_topics,              Helheim.ForumTopic
    has_many :forum_replies,             Helheim.ForumReply
    has_many :calendar_events,           Helheim.CalendarEvent
    belongs_to :verifier,                Helheim.User
  end

  def with_ids(query, ids) do
    from u in query, where: u.id in ^ids
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

  def not_confirmed(query) do
    from u in query, where: is_nil(u.confirmed_at)
  end

  def search(query, search_params) do
    query
    |> search_by_username(search_params["username"])
    |> search_by_location(search_params["location"])
  end

  def search_as_admin(query, ""), do: query
  def search_as_admin(query, search_params) do
    search(query, search_params)
    |> search_by_name(search_params["name"])
    |> search_by_email(search_params["email"])
    |> search_by_confirmed(search_params["confirmed"])
    |> search_by_ip(search_params["ip"])
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

  def search_by_confirmed(query, "1"), do: query |> confirmed()
  def search_by_confirmed(query, "0"), do: query |> not_confirmed()
  def search_by_confirmed(query, _), do: query

  def search_by_name(query, nil), do: query
  def search_by_name(query, ""), do: query
  def search_by_name(query, name) do
    from u in query, where: ilike(u.name, ^"%#{name}%")
  end

  def search_by_email(query, nil), do: query
  def search_by_email(query, ""), do: query
  def search_by_email(query, email) do
    from u in query, where: ilike(u.email, ^"%#{email}%")
  end

  def search_by_ip(query, nil), do: query
  def search_by_ip(query, ""), do: query
  def search_by_ip(query, ip) do
    from u in query, where: ilike(u.last_login_ip, ^"%#{ip}%") or ilike(u.previous_login_ip, ^"%#{ip}%")
  end

  def search_by_last_and_previous_ip(query, nil, nil), do: search_by_last_and_previous_ip(query, "-", "-")
  def search_by_last_and_previous_ip(query, last_ip, nil), do: search_by_last_and_previous_ip(query, last_ip, "-")
  def search_by_last_and_previous_ip(query, nil, previous_ip), do: search_by_last_and_previous_ip(query, "-", previous_ip)
  def search_by_last_and_previous_ip(query, last_ip, previous_ip) do
    from u in query,
      where: u.last_login_ip == ^last_ip or u.previous_login_ip == ^last_ip or u.last_login_ip == ^previous_ip or u.previous_login_ip == ^previous_ip
  end

  def sort(query, nil),             do: query
  def sort(query, "creation"),      do: from u in query, order_by: [desc: u.inserted_at]
  def sort(query, "login"),         do: from u in query, order_by: [fragment("? DESC NULLS LAST", u.last_login_at)]
  def sort(query, "id"),            do: sort(query, "id", "asc")
  def sort(query, "username"),      do: sort(query, "username", "asc")
  def sort(query, "name"),          do: sort(query, "name", "asc")
  def sort(query, "email"),         do: sort(query, "email", "asc")
  def sort(query, "inserted_at"),   do: sort(query, "inserted_at", "asc")
  def sort(query, "confirmed_at"),  do: sort(query, "confirmed_at", "asc")
  def sort(query, "last_login_at"), do: sort(query, "last_login_at", "asc")
  def sort(query, "last_login_ip"), do: sort(query, "last_login_ip", "asc")

  def sort(query, nil, _),                  do: query
  def sort(query, "", _),                   do: query
  def sort(query, "id", "asc"),             do: from u in query, order_by: [asc: u.id]
  def sort(query, "id", "desc"),            do: from u in query, order_by: [desc: u.id]
  def sort(query, "username", "asc"),       do: from u in query, order_by: [asc: u.username]
  def sort(query, "username", "desc"),      do: from u in query, order_by: [desc: u.username]
  def sort(query, "name", "asc"),           do: from u in query, order_by: [asc: u.name]
  def sort(query, "name", "desc"),          do: from u in query, order_by: [desc: u.name]
  def sort(query, "email", "asc"),          do: from u in query, order_by: [asc: u.email]
  def sort(query, "email", "desc"),         do: from u in query, order_by: [desc: u.email]
  def sort(query, "inserted_at", "asc"),    do: from u in query, order_by: [asc: u.inserted_at]
  def sort(query, "inserted_at", "desc"),   do: from u in query, order_by: [desc: u.inserted_at]
  def sort(query, "confirmed_at", "asc"),   do: from u in query, order_by: [fragment("? ASC NULLS LAST", u.confirmed_at)]
  def sort(query, "confirmed_at", "desc"),  do: from u in query, order_by: [fragment("? DESC NULLS LAST", u.confirmed_at)]
  def sort(query, "last_login_at", "asc"),  do: from u in query, order_by: [fragment("? ASC NULLS LAST", u.last_login_at)]
  def sort(query, "last_login_at", "desc"), do: from u in query, order_by: [fragment("? DESC NULLS LAST", u.last_login_at)]
  def sort(query, "last_login_ip", "asc"),  do: from u in query, order_by: [fragment("? ASC NULLS LAST", u.last_login_ip)]
  def sort(query, "last_login_ip", "desc"), do: from u in query, order_by: [fragment("? DESC NULLS LAST", u.last_login_ip)]
  def sort(query, "verified_at", "asc"),    do: from u in query, order_by: [fragment("? ASC NULLS LAST", u.verified_at)]
  def sort(query, "verified_at", "desc"),   do: from u in query, order_by: [fragment("? DESC NULLS LAST", u.verified_at)]

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

  def preferences_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:notification_sound, :mute_notifications])
    |> validate_inclusion(:notification_sound, Helheim.NotificationSounds.sound_keys())
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

  def verify!(_, %User{role: role}) when role != "admin", do: {:error, "Only admins can verify users!"}
  def verify!(user, admin) do
    case user.verified_at do
      nil ->
        Ecto.Changeset.change(user, verified_at: DateTime.utc_now, verifier_id: admin.id)
        |> Repo.update
      _ -> {:ok, user}
    end
  end

  def unverify!(user) do
    Ecto.Changeset.change(user, verified_at: nil, verifier_id: nil)
    |> Repo.update
  end

  def verified?(user) do
    !is_nil(user.verified_at)
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

  def mod?(%User{role: "mod"}), do: true
  def mod?(_), do: false

  def delete!(user) do
    photo_albums = assoc(user, :photo_albums) |> Repo.all
    Parallel.pmap(photo_albums, fn(pa) -> Helheim.PhotoAlbum.delete!(pa) end)
    Repo.delete!(user)
  end

  def age(%User{birthday: nil}, _), do: nil
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
        if HelheimWeb.Auth.password_correct?(password_hash, existing_password) do
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
        HelheimWeb.Email.registration_email(email, confirmation_token) |> Helheim.Mailer.deliver_later
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
