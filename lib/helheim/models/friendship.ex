defmodule Helheim.Friendship do
  use Helheim, :model

  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Friendship
  alias Helheim.User
  alias HelheimWeb.NotificationChannel
  import HelheimWeb.Gettext

  schema "friendships" do
    belongs_to :sender,    User
    belongs_to :recipient, User
    timestamps(type: :utc_datetime_usec)
    field :accepted_at,    :utc_datetime_usec
  end

  ## Changesets

  def request_changeset(struct, params) do
    struct
    |> cast(params, [])
    |> put_assoc(:sender, params.sender)
    |> put_assoc(:recipient, params.recipient)
    |> validate_required([:sender, :recipient])
    |> validate_different_recipient()
    |> validate_uniqueness()
  end

  def accept_changeset(struct, params) do
    struct
    |> cast(params, [:accepted_at])
    |> validate_required([:accepted_at])
  end

  ## Actions

  def request_friendship!(sender, recipient) do
    friendship = %Friendship{}
                 |> Friendship.request_changeset(%{sender: sender, recipient: recipient})

    Multi.new
    |> Multi.insert(:friendship, friendship)
    |> Multi.run(:push_notification, &push_notification/1)
    |> Repo.transaction
  end

  def accept_friendship!(recipient, sender) do
    Friendship
    |> from_sender(sender)
    |> to_recipient(recipient)
    |> pending()
    |> Repo.one!
    |> Friendship.accept_changeset(%{accepted_at: DateTime.utc_now})
    |> Repo.update()
  end

  def reject_friendship!(recipient, sender) do
    Friendship
    |> from_sender(sender)
    |> to_recipient(recipient)
    |> pending()
    |> Repo.one!
    |> Repo.delete()
  end

  def cancel_friendship!(user_a, user_b) do
    Friendship
    |> between_users(user_a, user_b)
    |> accepted()
    |> Repo.one!
    |> Repo.delete()
  end

  ## Chainable Queries

  # def between_users(query, %User{} = user_a, %User{} = user_b), do: between_users(query, user_a.id, user_b.id)
  def between_users(query, user_a, user_b) do
    from r in query,
      where: (r.sender_id == ^user_a.id and r.recipient_id == ^user_b.id) or
        (r.sender_id == ^user_b.id and r.recipient_id == ^user_a.id)
  end

  def to_recipient(query, user) do
    from r in query,
      where: r.recipient_id == ^user.id
  end

  def from_sender(query, user) do
    from r in query,
      where: r.sender_id == ^user.id
  end

  def pending(query) do
    from r in query,
      where: is_nil(r.accepted_at)
  end

  def accepted(query) do
    from r in query,
      where: not is_nil(r.accepted_at)
  end

  def for_user(query, user) do
    from r in query,
      where: (r.sender_id == ^user.id or r.recipient_id == ^user.id)
  end

  ## Queries

  def status(user_a, user_b) do
    friendship = Friendship
                 |> Friendship.between_users(user_a, user_b)
                 |> Repo.one
    cond do
      friendship && friendship.accepted_at -> :friends
      friendship                           -> :pending
      true                                 -> :not_friends
    end
  end

  def friend(current_user, friendship) do
    cond do
      friendship.sender.id    == current_user.id -> friendship.recipient
      friendship.recipient.id == current_user.id -> friendship.sender
      true -> raise RuntimeError, "current_user did not match sender or recipient of friendship"
    end
  end

  def count(user) do
    Friendship
    |> Friendship.for_user(user)
    |> Friendship.accepted()
    |> Repo.aggregate(:count, :id)
  end

  def pending_friendships(user) do
    Friendship
    |> Friendship.to_recipient(user)
    |> Friendship.pending()
    |> preload(:sender)
    |> Repo.all
  end

  ## Internals

  defp validate_different_recipient(changeset) do
    validate_change changeset, :recipient, fn _, _ ->
      user_a = changeset |> get_field(:sender)
      user_b = changeset |> get_field(:recipient)

      case user_a == user_b do
        true -> [{:recipient, gettext("You can't add yourself to your own contact list!")}]
        _ -> []
      end
    end
  end

  defp validate_uniqueness(%Ecto.Changeset{valid?: false} = changeset), do: changeset
  defp validate_uniqueness(changeset) do
    validate_change changeset, :recipient, fn _, _ ->
      user_a   = changeset |> get_field(:sender)
      user_b   = changeset |> get_field(:recipient)
      existing = Friendship
                 |> Friendship.between_users(user_a, user_b)
                 |> Repo.one()

      case existing do
        %Friendship{} -> [{:recipient, gettext("There is already a pending request between the two of you!")}]
        _ -> []
      end
    end
  end

  defp push_notification(%{friendship: friendship}) do
    NotificationChannel.broadcast_notification(friendship.recipient_id)
    {:ok, friendship}
  end
end
