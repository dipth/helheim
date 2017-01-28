defmodule Helheim.NotificationTest do
  use Helheim.ModelCase
  alias Helheim.Notification

  @valid_attrs %{title: "Some Notification!"}
  @invalid_attrs %{title: "   "}

  test "changeset with valid attributes" do
    changeset = Notification.changeset(%Notification{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Notification.changeset(%Notification{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "newest orders newer notifications before older ones" do
    notification_1 = insert(:notification)
    notification_2 = insert(:notification)
    notifications = Notification |> Notification.newest |> Repo.all
    [first, last] = notifications
    assert first.id == notification_2.id
    assert last.id == notification_1.id
  end

  test "unread only returns notifications where read_at is null" do
    notification = insert(:notification, read_at: nil)
    insert(:notification, read_at: DateTime.utc_now)
    notifications = Notification |> Notification.unread |> Repo.all
    [first] = notifications
    assert first.id == notification.id
  end
end
