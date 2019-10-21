defmodule Helheim.FriendshipTest do
  use Helheim.DataCase
  import Mock
  alias Helheim.Repo
  alias Helheim.Friendship
  alias HelheimWeb.NotificationChannel

  ## Changesets

  describe "request_changeset/2" do
    test "it is valid with valid with valid params" do
      params    = %{sender: insert(:user), recipient: insert(:user)}
      changeset = Friendship.request_changeset(%Friendship{}, params)
      assert changeset.valid?
    end

    test "it requires a sender" do
      params    = %{sender: nil, recipient: insert(:user)}
      changeset = Friendship.request_changeset(%Friendship{}, params)
      refute changeset.valid?
    end

    test "it requires a recipient" do
      params    = %{sender: insert(:user), recipient: nil}
      changeset = Friendship.request_changeset(%Friendship{}, params)
      refute changeset.valid?
    end

    test "it does not allow multiple requests from the same sender to the same recipient" do
      request   = insert(:friendship_request)
      params    = %{sender: request.sender, recipient: request.recipient}
      changeset = Friendship.request_changeset(%Friendship{}, params)
      refute changeset.valid?
    end

    test "it does not allow requests to a recipient that already sent another request to the sender" do
      request   = insert(:friendship_request)
      params    = %{sender: request.recipient, recipient: request.sender}
      changeset = Friendship.request_changeset(%Friendship{}, params)
      refute changeset.valid?
    end

    test "it does not allow requests from a sender to him or herself" do
      user      = insert(:user)
      params    = %{sender: user, recipient: user}
      changeset = Friendship.request_changeset(%Friendship{}, params)
      refute changeset.valid?
    end
  end

  describe "accept_changeset/2" do
    test "it is valid with valid params" do
      request   = insert(:friendship_request)
      params    = %{accepted_at: DateTime.utc_now}
      changeset = Friendship.accept_changeset(request, params)
      assert changeset.valid?
    end

    test "it requires an accepted_at timestamp" do
      request   = insert(:friendship_request)
      params    = %{accepted_at: nil}
      changeset = Friendship.accept_changeset(request, params)
      refute changeset.valid?
    end
  end

  ## Actions

  describe "request_friendship!/2" do
    test "it creates a pending friendship between the sender and recipient" do
      sender    = insert(:user)
      recipient = insert(:user)
      assert {:ok, %{friendship: friendship}} = Friendship.request_friendship!(sender, recipient)
      assert friendship.id
      assert friendship.sender == sender
      assert friendship.recipient == recipient
      refute friendship.accepted_at
    end

    test_with_mock "it triggers a notification for the recipient",
      NotificationChannel, [], [broadcast_notification: fn(_user_id) -> nil end] do

      sender    = insert(:user)
      recipient = insert(:user)
      Friendship.request_friendship!(sender, recipient)
      assert_called NotificationChannel.broadcast_notification(recipient.id)
    end
  end

  describe "accept_friendship!/2" do
    test "it accepts a pending request to the recipient from the sender" do
      request = insert(:friendship_request)
      assert {:ok, friendship} = Friendship.accept_friendship!(request.recipient, request.sender)
      assert friendship.accepted_at
    end

    test "it raises an error for an already accepted request" do
      friendship = insert(:friendship)
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none/, fn ->
        Friendship.accept_friendship!(friendship.recipient, friendship.sender)
      end
    end

    test "it raises an error if no request exists between the recipient and sender" do
      sender = insert(:user)
      recipient = insert(:user)
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none/, fn ->
        Friendship.accept_friendship!(recipient, sender)
      end
    end
  end

  describe "reject_friendship!/2" do
    test "it deletes the pending request to the recipient from the sender" do
      request = insert(:friendship_request)
      assert {:ok, _friendship} = Friendship.reject_friendship!(request.recipient, request.sender)
      refute Repo.one(Friendship)
    end

    test "it raises an error for an already accepted request" do
      friendship = insert(:friendship)
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none/, fn ->
        Friendship.reject_friendship!(friendship.recipient, friendship.sender)
      end
    end

    test "it raises an error if no request exists between the recipient and sender" do
      sender = insert(:user)
      recipient = insert(:user)
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none/, fn ->
        Friendship.reject_friendship!(recipient, sender)
      end
    end
  end

  describe "cancel_friendship!/2" do
    test "it deletes the active friendship between the two users" do
      friendship = insert(:friendship)
      assert {:ok, _friendship} = Friendship.cancel_friendship!(friendship.recipient, friendship.sender)
      refute Repo.one(Friendship)
    end

    test "it raises an error if the friendship is pending" do
      friendship = insert(:friendship_request)
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none/, fn ->
        Friendship.cancel_friendship!(friendship.recipient, friendship.sender)
      end
    end

    test "it raises an error if no friendship exists between the two users" do
      user_a = insert(:user)
      user_b = insert(:user)
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none/, fn ->
        Friendship.cancel_friendship!(user_a, user_b)
      end
    end
  end

  ## Chainable Queries

  describe "between_users/3" do
    test "it returns only friendships between the two users" do
      user_a          = insert(:user)
      user_b          = insert(:user)
      user_c          = insert(:user)
      friendship_a_b  = insert(:friendship, sender: user_a, recipient: user_b)
      _friendship_a_c = insert(:friendship, sender: user_a, recipient: user_c)
      friendships     = Friendship |> Friendship.between_users(user_a, user_b) |> Repo.all
      ids             = Enum.map friendships, fn(f) -> f.id end

      assert [friendship_a_b.id] == ids
    end
  end

  describe "to_recipient/2" do
    test "it returns only friendships sent to the given user" do
      friendship_a  = insert(:friendship)
      _friendship_b = insert(:friendship)
      friendships   = Friendship |> Friendship.to_recipient(friendship_a.recipient) |> Repo.all
      ids           = Enum.map friendships, fn(f) -> f.id end

      assert [friendship_a.id] == ids
    end
  end

  describe "from_sender/2" do
    test "it returns only friendships sent by the given user" do
      friendship_a  = insert(:friendship)
      _friendship_b = insert(:friendship)
      friendships   = Friendship |> Friendship.from_sender(friendship_a.sender) |> Repo.all
      ids           = Enum.map friendships, fn(f) -> f.id end

      assert [friendship_a.id] == ids
    end
  end

  describe "pending/1" do
    test "it returns only pending friendships" do
      friendship_a  = insert(:friendship, accepted_at: nil)
      _friendship_b = insert(:friendship)
      friendships   = Friendship |> Friendship.pending() |> Repo.all
      ids           = Enum.map friendships, fn(f) -> f.id end

      assert [friendship_a.id] == ids
    end
  end

  describe "accepted/1" do
    test "it returns only accepted friendships" do
      friendship_a  = insert(:friendship)
      _friendship_b = insert(:friendship, accepted_at: nil)
      friendships   = Friendship |> Friendship.accepted() |> Repo.all
      ids           = Enum.map friendships, fn(f) -> f.id end

      assert [friendship_a.id] == ids
    end
  end

  describe "for_user/2" do
    test "it returns only friendships sent or received by the given user" do
      user_a         = insert(:user)
      user_b         = insert(:user)
      user_c         = insert(:user)
      friendship_a_b = insert(:friendship, sender: user_a, recipient: user_b)
      friendship_a_c = insert(:friendship, sender: user_c, recipient: user_a)
      friendship_b_c = insert(:friendship, sender: user_b, recipient: user_c)
      friendships    = Friendship |> Friendship.for_user(user_a) |> Repo.all
      ids            = Enum.map friendships, fn(f) -> f.id end

      assert Enum.member?(ids, friendship_a_b.id)
      assert Enum.member?(ids, friendship_a_c.id)
      refute Enum.member?(ids, friendship_b_c.id)
    end
  end

  ## Queries

  describe "status/2" do
    test "it returns :friends if an accepted friendship exists between the given users" do
      friendship = insert(:friendship)
      assert :friends = Friendship.status(friendship.sender, friendship.recipient)
    end

    test "it returns :pending if a pending friendship exists between the given users" do
      friendship = insert(:friendship_request)
      assert :pending = Friendship.status(friendship.sender, friendship.recipient)
    end

    test "it returns :not_friends if no friendship exists between the given users" do
      user_a = insert(:user)
      user_b = insert(:user)
      assert :not_friends = Friendship.status(user_a, user_b)
    end
  end

  describe "friend/2" do
    test "it returns the sender of the given friendship if the recipient is the same as the given user" do
      friendship = insert(:friendship)
      friend     = Friendship.friend(friendship.recipient, friendship)
      assert friend == friendship.sender
    end

    test "it returns the recipient of the given friendship if the sender is the same as the given user" do
      friendship = insert(:friendship)
      friend     = Friendship.friend(friendship.sender, friendship)
      assert friend == friendship.recipient
    end

    test "it raises an error if neither the recipient or the sender of the given friendship match the given user" do
      friendship = insert(:friendship)
      user       = insert(:user)
      assert_raise RuntimeError, ~r/current_user did not match sender or recipient of friendship/, fn ->
        Friendship.friend(user, friendship)
      end
    end
  end

  describe "count/1" do
    test "it returns the number of accepted friendships involving the given user" do
      user = insert(:user)
      insert(:friendship, sender: user)
      insert(:friendship, recipient: user)
      insert(:friendship_request, recipient: user)
      insert(:friendship)

      assert 2 = Friendship.count(user)
    end
  end
end
