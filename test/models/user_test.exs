defmodule Helheim.UserTest do
  use Helheim.ModelCase
  alias Helheim.Repo
  alias Helheim.User
  import Helheim.Factory

  @valid_registration_attrs %{name: "Foo Bar", username: "foobar", email: "foo@bar.dk", password: "password"}
  @invalid_registration_attrs %{}

  describe "registration_changeset/2" do
    test "it accepts valid attributes" do
      changeset = User.registration_changeset(%User{}, @valid_registration_attrs)
      assert changeset.valid?
    end

    test "It rejects invalid attributes" do
      changeset = User.registration_changeset(%User{}, @invalid_registration_attrs)
      refute changeset.valid?
    end

    test "It rejects duplicate usernames regardles of case" do
      %User{}
      |> User.registration_changeset(@valid_registration_attrs)
      |> Repo.insert!

      user2 =
        %User{}
        |> User.registration_changeset(@valid_registration_attrs |> Map.merge(%{username: "FOOBAR", email: "something@else.dk"}))

      assert {:error, changeset} = Repo.insert(user2)
      assert {"has already been taken", _} = changeset.errors[:username]
    end

    test "It rejects duplicate e-mail addresses regardles of case" do
      %User{}
      |> User.registration_changeset(@valid_registration_attrs)
      |> Repo.insert!

      user2 =
        %User{}
        |> User.registration_changeset(@valid_registration_attrs |> Map.merge(%{username: "somethingelse", email: "FOO@BAR.DK"}))

      assert {:error, changeset} = Repo.insert(user2)
      assert {"has already been taken", _} = changeset.errors[:email]
    end
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

  describe "confirmed?/1" do
    test "it returns true if the confirmed_at timestamp is set" do
      user = insert(:user, confirmed_at: DateTime.utc_now)
      assert User.confirmed?(user)
    end

    test "it returns false if the confirmed_at timestamp is not set" do
      user = insert(:user, confirmed_at: nil)
      refute User.confirmed?(user)
    end
  end

  describe "admin?/1" do
    test "it returns true if the role of the user is 'admin'" do
      user = insert(:user, role: "admin")
      assert User.admin?(user)
    end

    test "it returns false if the role of the user is not 'admin'" do
      user = insert(:user, role: "nope")
      refute User.admin?(user)
    end
  end
end
