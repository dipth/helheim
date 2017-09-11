defmodule Helheim.UserTest do
  use Helheim.ModelCase
  import Mock
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.PhotoAlbum
  import Helheim.Factory

  describe "registration_changeset/2" do
    @valid_registration_attrs %{name: "Foo Bar", username: "foobar", email: "foo@bar.dk", password: "password"}
    @invalid_registration_attrs %{}

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

  describe "profile_changeset/2" do
    setup [:create_user]

    test "it allows changing the gender", %{user: user} do
      user = User.profile_changeset(user, %{gender: "Foo"})
             |> Repo.update!
      assert user.gender == "Foo"
    end

    test "it trims the gender value", %{user: user} do
      user = User.profile_changeset(user, %{gender: "   Foo   "})
             |> Repo.update!
      assert user.gender == "Foo"
    end

    test "it allows a custom value for gender", %{user: user} do
      user = User.profile_changeset(user, %{gender: "%%CUSTOM%%", gender_custom: "Bar"})
             |> Repo.update!
      assert user.gender == "Bar"
    end

    test "it trims the custom value for gender", %{user: user} do
      user = User.profile_changeset(user, %{gender: "%%CUSTOM%%", gender_custom: "   Bar   "})
             |> Repo.update!
      assert user.gender == "Bar"
    end

    test "it clears the gender if trying to set a custom value without providing a custom value", %{user: user} do
      user = User.profile_changeset(user, %{gender: "%%CUSTOM%%"})
             |> Repo.update!
      assert user.gender == nil
    end

    test "it allows changing the partnership_status", %{user: user} do
      user = User.profile_changeset(user, %{partnership_status: "Foo"})
             |> Repo.update!
      assert user.partnership_status == "Foo"
    end

    test "it trims the partnership_status value", %{user: user} do
      user = User.profile_changeset(user, %{partnership_status: "   Foo   "})
             |> Repo.update!
      assert user.partnership_status == "Foo"
    end

    test "it allows a custom value for partnership_status", %{user: user} do
      user = User.profile_changeset(user, %{partnership_status: "%%CUSTOM%%", partnership_status_custom: "Bar"})
             |> Repo.update!
      assert user.partnership_status == "Bar"
    end

    test "it trims the custom value for partnership_status", %{user: user} do
      user = User.profile_changeset(user, %{partnership_status: "%%CUSTOM%%", partnership_status_custom: "   Bar   "})
             |> Repo.update!
      assert user.partnership_status == "Bar"
    end

    test "it clears the partnership_status if trying to set a custom value without providing a custom value", %{user: user} do
      user = User.profile_changeset(user, %{partnership_status: "%%CUSTOM%%"})
             |> Repo.update!
      assert user.partnership_status == nil
    end

    test "it allows changing the location", %{user: user} do
      user = User.profile_changeset(user, %{location: "Foo"})
             |> Repo.update!
      assert user.location == "Foo"
    end

    test "it trims the location value", %{user: user} do
      user = User.profile_changeset(user, %{location: "   Foo   "})
             |> Repo.update!
      assert user.location == "Foo"
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

  describe "delete/1" do
    test_with_mock "it calls PhotoAlbum.delete! for each photo album belonging to the user",
      PhotoAlbum, [:passthrough], [delete!: fn(_photo_album) -> {:ok} end] do

      user         = insert(:user)
      photo_album1 = Repo.get_by(PhotoAlbum, id: insert(:photo_album, user: user).id)
      photo_album2 = Repo.get_by(PhotoAlbum, id: insert(:photo_album, user: user).id)
      photo_album3 = Repo.get_by(PhotoAlbum, id: insert(:photo_album).id)

      User.delete! user

      assert called PhotoAlbum.delete!(photo_album1)
      assert called PhotoAlbum.delete!(photo_album2)
      refute called PhotoAlbum.delete!(photo_album3)
    end

    test_with_mock "it tracks the deletion of the user",
      Helheim.DeletedUser, [], [track_deletion!: fn(_user) -> {:ok, nil} end] do

      user = insert(:user)
      User.delete! user
      assert called Helheim.DeletedUser.track_deletion!(user)
    end

    test "it deletes the user" do
      user = insert(:user)
      User.delete! user
      refute Repo.get(User, user.id)
    end
  end

  describe "age/1" do
    test "it returns the number of full years between the birthday of a user and the current date" do
      now = Timex.now
      birthday = Timex.set(now, year: now.year - 10) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user) == 10
    end

    test "it correctly subtracts 1 if the current month is before the month of the birthday" do
      now = Timex.now
      birthday = Timex.set(now, year: now.year - 10, month: now.month + 1) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user) == 9
    end

    test "it correctly subtracts 1 if the current month is the same as the month of the birthday but the current day is before" do
      now = Timex.now
      birthday = Timex.set(now, year: now.year - 10, day: now.day + 1) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user) == 9
    end

    test "it does not subtract 1 if the current day is before the day of the birthday but the current month is after" do
      now = Timex.now
      birthday = Timex.set(now, year: now.year - 10, month: now.month - 1, day: now.day + 1) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user) == 10
    end
  end

  describe "foreign keys" do
    test "all associated blog posts are deleted when a user is deleted" do
      user      = insert(:user)
      blog_post = insert(:blog_post, user: user)
      Repo.delete!(user)
      refute Repo.get(Helheim.BlogPost, blog_post.id)
    end

    test "all authored comments are nilified when a user is deleted" do
      user              = insert(:user)
      blog_post_comment = insert(:blog_post_comment, author: user)
      profile_comment   = insert(:profile_comment, author: user)
      Repo.delete!(user)
      assert Repo.get(Helheim.Comment, blog_post_comment.id).author_id == nil
      assert Repo.get(Helheim.Comment, profile_comment.id).author_id   == nil
    end

    test "all associated forum topics are nilified when a user is deleted" do
      user = insert(:user)
      forum_topic = insert(:forum_topic, user: user)
      Repo.delete!(user)
      assert Repo.get(Helheim.ForumTopic, forum_topic.id).user_id == nil
    end

    test "all associated forum replies are nilified when a user is deleted" do
      user = insert(:user)
      forum_reply = insert(:forum_reply, user: user)
      Repo.delete!(user)
      assert Repo.get(Helheim.ForumReply, forum_reply.id).user_id == nil
    end
  end

  describe "banned?/1" do
    test "returns false for a user with a blank banned_until value" do
      user = insert(:user, banned_until: nil)
      refute User.banned?(user)
    end

    test "returns false for a user with a banned_until value in the past" do
      user = insert(:user, banned_until: Timex.shift(Timex.now, minutes: -1))
      refute User.banned?(user)
    end

    test "returns true for a user with a banned_until value in the future" do
      user = insert(:user, banned_until: Timex.shift(Timex.now, minutes: 1))
      assert User.banned?(user)
    end
  end

  describe "confirmed/1" do
    test "returns users where confirmed_at is not blank" do
      id = insert(:user, confirmed_at: Timex.now).id
      user = User |> User.confirmed |> Repo.one
      assert user.id == id
    end

    test "does not return users where confirmed_at is blank" do
      insert(:user, confirmed_at: nil).id
      users = User |> User.confirmed |> Repo.all
      assert length(users) == 0
    end
  end

  describe "track_login!/2" do
    test "it sets last_login_at to the current utc time" do
      user = insert(:user)
      {:ok, user} = User.track_login!(user, "127.0.0.1")
      {:ok, time_diff, _, _} = Calendar.DateTime.diff(user.last_login_at, DateTime.utc_now)
      assert time_diff < 10
    end

    test "it sets last_login_ip to the specified ip address" do
      user = insert(:user)
      {:ok, user} = User.track_login!(user, "127.0.0.1")
      assert user.last_login_ip == "127.0.0.1"
    end

    test "it copies the existing last_login_at to previous_login_at" do
      existing_last_login_at = Timex.shift(Timex.now, days: -10)
      user = insert(:user, last_login_at: existing_last_login_at)
      {:ok, user} = User.track_login!(user, "127.0.0.1")
      assert user.previous_login_at == existing_last_login_at
    end

    test "it copies the existing last_login_ip to previous_login_ip" do
      user = insert(:user, last_login_ip: "192.168.0.1")
      {:ok, user} = User.track_login!(user, "127.0.0.1")
      assert user.previous_login_ip == "192.168.0.1"
    end

    test "correctly handles an edge case where the specified user is nil" do
      {:ok, nil} = User.track_login!(nil, "127.0.0.1")
    end
  end

  describe "recently_logged_in/1" do
    test "it orders users who have recently logged in before older ones" do
      user1 = insert(:user, last_login_at: Timex.shift(Timex.now, minutes: -1))
      user2 = insert(:user, last_login_at: Timex.shift(Timex.now, minutes: -2))
      [first, last] = User |> User.recently_logged_in |> Repo.all
      assert first.id == user1.id
      assert last.id  == user2.id
    end

    test "it does not include users who have never logged in" do
      user1 = insert(:user, last_login_at: Timex.now)
      user2 = insert(:user, last_login_at: nil)
      user_ids = User |> User.recently_logged_in |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      refute Enum.member?(user_ids, user2.id)
    end
  end

  describe "search_by_username/2" do
    test "it finds users where the username match the search term case insensitive" do
      user1 = insert(:user, username: "FoO")
      user2 = insert(:user, username: "FoOo")
      user3 = insert(:user, username: "Bar")
      user_ids = User |> User.search_by_username("oo") |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      assert Enum.member?(user_ids, user2.id)
      refute Enum.member?(user_ids, user3.id)
    end

    test "it returns all users if the search term is blank" do
      user1 = insert(:user, username: "FoO")
      user2 = insert(:user, username: "FoOo")
      user3 = insert(:user, username: "Bar")
      user_ids = User |> User.search_by_username("") |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      assert Enum.member?(user_ids, user2.id)
      assert Enum.member?(user_ids, user3.id)
    end

    test "it returns all users if the search term is nil" do
      user1 = insert(:user, username: "FoO")
      user2 = insert(:user, username: "FoOo")
      user3 = insert(:user, username: "Bar")
      user_ids = User |> User.search_by_username(nil) |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      assert Enum.member?(user_ids, user2.id)
      assert Enum.member?(user_ids, user3.id)
    end
  end

  describe "search_by_location/2" do
    test "it finds users where the location match the search term case insensitive" do
      user1 = insert(:user, location: "FoO")
      user2 = insert(:user, location: "FoOo")
      user3 = insert(:user, location: "Bar")
      user_ids = User |> User.search_by_location("oo") |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      assert Enum.member?(user_ids, user2.id)
      refute Enum.member?(user_ids, user3.id)
    end

    test "it returns all users if the search term is blank" do
      user1 = insert(:user, location: "FoO")
      user2 = insert(:user, location: "FoOo")
      user3 = insert(:user, location: "Bar")
      user_ids = User |> User.search_by_location("") |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      assert Enum.member?(user_ids, user2.id)
      assert Enum.member?(user_ids, user3.id)
    end

    test "it returns all users if the search term is nil" do
      user1 = insert(:user, location: "FoO")
      user2 = insert(:user, location: "FoOo")
      user3 = insert(:user, location: "Bar")
      user_ids = User |> User.search_by_location(nil) |> Repo.all |> Enum.map(fn(p) -> p.id end)
      assert Enum.member?(user_ids, user1.id)
      assert Enum.member?(user_ids, user2.id)
      assert Enum.member?(user_ids, user3.id)
    end
  end

  describe "sort/2" do
    test "orders newer users before older users when passing `creation` as the ordering key" do
      user1 = insert(:user, inserted_at: Timex.shift(Timex.now, minutes: -1))
      user2 = insert(:user, inserted_at: Timex.shift(Timex.now, minutes: -2))
      [first, last] = User |> User.sort("creation") |> Repo.all
      assert first.id == user1.id
      assert last.id  == user2.id
    end

    test "orders recently logged in users before others when passing `login` as the ordering key" do
      user1 = insert(:user, last_login_at: Timex.shift(Timex.now, minutes: -1))
      user2 = insert(:user, last_login_at: Timex.shift(Timex.now, minutes: -2))
      user3 = insert(:user, last_login_at: nil)
      [first, second, last] = User |> User.sort("login") |> Repo.all
      assert first.id  == user1.id
      assert second.id == user2.id
      assert last.id   == user3.id
    end

    test "does not order the users in any explicit way when passing `nil` as the ordering key" do
      user1 = insert(:user)
      user2 = insert(:user)
      [first, last] = User |> User.sort(nil) |> Repo.all
      assert first.id == user1.id
      assert last.id  == user2.id
    end
  end
end
