defmodule Helheim.DeletedUserTest do
  use Helheim.ModelCase
  import Helheim.Factory
  alias Helheim.DeletedUser

  @valid_attrs %{
    original_id:          123,
    username:             "foobar",
    email:                "foo@bar.dk",
    name:                 "Foo Bar",
    original_inserted_at: Timex.shift(Timex.now, days: -1)
  }

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = DeletedUser.changeset(%DeletedUser{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires an original_id" do
      changeset = DeletedUser.changeset(%DeletedUser{}, Map.delete(@valid_attrs, :original_id))
      refute changeset.valid?
    end

    test "it requires a username" do
      changeset = DeletedUser.changeset(%DeletedUser{}, Map.delete(@valid_attrs, :username))
      refute changeset.valid?
    end

    test "it requires an email" do
      changeset = DeletedUser.changeset(%DeletedUser{}, Map.delete(@valid_attrs, :email))
      refute changeset.valid?
    end

    test "it requires a name" do
      changeset = DeletedUser.changeset(%DeletedUser{}, Map.delete(@valid_attrs, :name))
      refute changeset.valid?
    end

    test "it requires an original_inserted_at timestamp" do
      changeset = DeletedUser.changeset(%DeletedUser{}, Map.delete(@valid_attrs, :original_inserted_at))
      refute changeset.valid?
    end
  end

  describe "track_deletion!/1" do
    test "creates a new DeletedUser from the details of the specified User" do
      user = insert(:user)
      {:ok, deleted_user} = DeletedUser.track_deletion!(user)
      assert deleted_user.original_id          == user.id
      assert deleted_user.username             == user.username
      assert deleted_user.email                == user.email
      assert deleted_user.name                 == user.name
      assert deleted_user.banned_until         == user.banned_until
      assert deleted_user.ban_reason           == user.ban_reason
      assert deleted_user.confirmed_at         == user.confirmed_at
      assert deleted_user.last_login_at        == user.last_login_at
      assert deleted_user.last_login_ip        == user.last_login_ip
      assert deleted_user.previous_login_at    == user.previous_login_at
      assert deleted_user.previous_login_ip    == user.previous_login_ip
      assert deleted_user.original_inserted_at == user.inserted_at
      assert deleted_user.original_updated_at  == user.updated_at
    end
  end
end
