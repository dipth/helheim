defmodule Altnation.UserTest do
  use Altnation.ModelCase
  alias Altnation.User
  import Altnation.Factory

  @valid_registration_attrs %{name: "Foo Bar", username: "foobar", email: "foo@bar.dk", password: "password"}
  @invalid_registration_attrs %{}

  test "registration_changeset with valid attributes" do
    changeset = User.registration_changeset(%User{}, @valid_registration_attrs)
    assert changeset.valid?
  end

  test "registration_changeset with invalid attributes" do
    changeset = User.registration_changeset(%User{}, @invalid_registration_attrs)
    refute changeset.valid?
  end

  describe "confirm!/1" do
    test "it sets the confirmed_at timestamp if it is blank" do
      user = insert(:user, confirmed_at: nil)
      assert user.confirmed_at == nil
      {:ok, user} = User.confirm!(user)
      refute user.confirmed_at == nil
    end

    test "it does not update the confirmed_at timestamp if it is already set" do
      {:ok, confirmed_at} = Calendar.DateTime.Parse.rfc3339_utc("2015-01-01T00:00:00Z")
      user = insert(:user, confirmed_at: confirmed_at)
      {:ok, user} = User.confirm!(user)
      assert user.confirmed_at == confirmed_at
    end
  end
end
