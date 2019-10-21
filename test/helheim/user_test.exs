defmodule Helheim.UserTest do
  use Helheim.DataCase
  import Mock
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.PhotoAlbum
  import Helheim.Factory

  describe "registration_changeset/2" do
    @valid_registration_attrs %{name: "Foo Bar", username: "foobar", email: "foo@bar.dk", password: "password", captcha: "valid_response"}
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

  describe "preferences_changeset/2" do
    @valid_preferences_attrs %{notification_sound: "chime_1", mute_notifications: nil}

    test "it accepts valid attributes" do
      changeset = User.preferences_changeset(%User{}, @valid_preferences_attrs)
      assert changeset.valid?
    end

    test "It rejects invalid notification sounds" do
      changeset = User.preferences_changeset(%User{}, Map.merge(@valid_registration_attrs, %{notification_sound: "blah"}))
      refute changeset.valid?
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

  describe "mod?/1" do
    test "it returns true if the role of the user is 'mod'" do
      user = insert(:user, role: "mod")
      assert User.mod?(user)
    end

    test "it returns false if the role of the user is not 'mod'" do
      user = insert(:user, role: "nope")
      refute User.mod?(user)
    end
  end

  describe "mod_or_admin?/1" do
    test "it returns true if the role of the user is 'mod'" do
      user = insert(:user, role: "mod")
      assert User.mod_or_admin?(user)
    end

    test "it returns true if the role of the user is 'admin'" do
      user = insert(:user, role: "admin")
      assert User.mod_or_admin?(user)
    end

    test "it returns false if the role of the user is not 'mod' or 'admin'" do
      user = insert(:user, role: "nope")
      refute User.mod_or_admin?(user)
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

      assert_called PhotoAlbum.delete!(photo_album1)
      assert_called PhotoAlbum.delete!(photo_album2)
      refute called PhotoAlbum.delete!(photo_album3)
    end

    test "it deletes the user" do
      user = insert(:user)
      User.delete! user
      refute Repo.get(User, user.id)
    end
  end

  describe "age/2" do
    test "it returns the number of full years between the birthday of a user and the current date" do
      now = Timex.set(Timex.now, day: 1, month: 5)
      birthday = Timex.set(now, year: now.year - 10) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user, now) == 10
    end

    test "it correctly subtracts 1 if the current month is before the month of the birthday" do
      now = Timex.set(Timex.now, day: 1, month: 5)
      birthday = Timex.set(now, year: now.year - 10, month: now.month + 1) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user, now) == 9
    end

    test "it correctly subtracts 1 if the current month is the same as the month of the birthday but the current day is before" do
      now = Timex.set(Timex.now, day: 1, month: 5)
      birthday = Timex.set(now, year: now.year - 10, day: now.day + 1) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user, now) == 9
    end

    test "it does not subtract 1 if the current day is before the day of the birthday but the current month is after" do
      now = Timex.set(Timex.now, day: 1, month: 5)
      birthday = Timex.set(now, year: now.year - 10, month: now.month - 1, day: now.day + 1) |> Timex.to_date
      user = insert(:user, birthday: birthday)
      assert User.age(user, now) == 10
    end

    test "returns nil for a user without a birthday" do
      user = build(:user, birthday: nil)
      assert User.age(user, Timex.now) == nil
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

  describe "not_confirmed/1" do
    test "returns users where confirmed_at is blank" do
      id = insert(:user, confirmed_at: nil).id
      user = User |> User.not_confirmed |> Repo.one
      assert user.id == id
    end

    test "does not return users where confirmed_at is not blank" do
      insert(:user, confirmed_at: Timex.now).id
      users = User |> User.not_confirmed |> Repo.all
      assert length(users) == 0
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

  test "search_by_confirmed/2" do
    user1 = insert(:user, confirmed_at: nil)
    user2 = insert(:user, confirmed_at: Timex.now)
    assert user1 == User |> User.search_by_confirmed("0") |> Repo.one
    assert user2 == User |> User.search_by_confirmed("1") |> Repo.one
    assert [user1, user2] == User |> User.search_by_confirmed(nil) |> Repo.all
  end

  test "search_by_name/2" do
    user1 = insert(:user, name: "Foof")
    user2 = insert(:user, name: "Barb")
    assert user1 == User |> User.search_by_name("Oo") |> Repo.one
    assert user2 == User |> User.search_by_name("Ar") |> Repo.one
    assert [user1, user2] == User |> User.search_by_name("") |> Repo.all
    assert [user1, user2] == User |> User.search_by_name(nil) |> Repo.all
  end

  test "search_by_email/2" do
    user1 = insert(:user, email: "foof@test.com")
    user2 = insert(:user, email: "barb@test.com")
    assert user1 == User |> User.search_by_email("Oo") |> Repo.one
    assert user2 == User |> User.search_by_email("Ar") |> Repo.one
    assert [user1, user2] == User |> User.search_by_email("") |> Repo.all
    assert [user1, user2] == User |> User.search_by_email(nil) |> Repo.all
  end

  test "search_by_ip/2" do
    user1 = insert(:user, last_login_ip: "1.2.3.4", previous_login_ip: "2.3.4.5")
    user2 = insert(:user, last_login_ip: "2.3.4.5", previous_login_ip: "1.2.3.4")
    user3 = insert(:user, last_login_ip: "1.2.3.4", previous_login_ip: "3.4.5.6")
    user4 = insert(:user, last_login_ip: "3.4.5.6", previous_login_ip: "1.2.3.4")
    user5 = insert(:user, last_login_ip: "1.2.3.4", previous_login_ip: nil)
    user6 = insert(:user, last_login_ip: nil, previous_login_ip: "1.2.3.4")
    user7 = insert(:user, last_login_ip: nil, previous_login_ip: nil)

    assert [user1, user2, user3, user4, user5, user6] == User |> User.search_by_ip("1.2.3.4") |> Repo.all
    assert [user1, user2] == User |> User.search_by_ip("2.3.4.5") |> Repo.all
    assert [user3, user4] == User |> User.search_by_ip("3.4.5.6") |> Repo.all
    assert [user1, user2, user3, user4, user5, user6, user7] == User |> User.search_by_ip("") |> Repo.all
    assert [user1, user2, user3, user4, user5, user6, user7] == User |> User.search_by_ip(nil) |> Repo.all
  end

  test "search_by_last_and_previous_ip/3" do
    user1 = insert(:user, last_login_ip: "1.2.3.4", previous_login_ip: "2.3.4.5")
    user2 = insert(:user, last_login_ip: "2.3.4.5", previous_login_ip: "1.2.3.4")
    user3 = insert(:user, last_login_ip: "1.2.3.4", previous_login_ip: "3.4.5.6")
    user4 = insert(:user, last_login_ip: "3.4.5.6", previous_login_ip: "1.2.3.4")
    user5 = insert(:user, last_login_ip: "1.2.3.4", previous_login_ip: nil)
    user6 = insert(:user, last_login_ip: nil, previous_login_ip: "1.2.3.4")
    _user7 = insert(:user, last_login_ip: nil, previous_login_ip: nil)

    assert [user1, user2, user3, user4, user5, user6] == User |> User.search_by_last_and_previous_ip("1.2.3.4", "") |> Repo.all
    assert [user1, user2, user3, user4, user5, user6] == User |> User.search_by_last_and_previous_ip("1.2.3.4", nil) |> Repo.all
    assert [user1, user2, user3, user4, user5, user6] == User |> User.search_by_last_and_previous_ip("", "1.2.3.4") |> Repo.all
    assert [user1, user2, user3, user4, user5, user6] == User |> User.search_by_last_and_previous_ip(nil, "1.2.3.4") |> Repo.all
    assert [user1, user2, user3, user4] == User |> User.search_by_last_and_previous_ip("2.3.4.5", "3.4.5.6") |> Repo.all
    assert [] == User |> User.search_by_last_and_previous_ip("", "") |> Repo.all
    assert [] == User |> User.search_by_last_and_previous_ip(nil, nil) |> Repo.all
  end

  test "sort/2" do
    insert(:user,
      id: 1,
      username: "aaa",
      name: "Aaa",
      email: "aaa@aaa.aaa",
      inserted_at: Timex.shift(Timex.now, minutes: -1),
      last_login_at: Timex.shift(Timex.now, minutes: -1),
      last_login_ip: "127.0.0.1",
      confirmed_at: Timex.shift(Timex.now, minutes: -1)
    )

    insert(:user,
      id: 2,
      username: "bbb",
      name: "Bbb",
      email: "bbb@bbb.bbb",
      inserted_at: Timex.shift(Timex.now, minutes: -2),
      last_login_at: Timex.shift(Timex.now, minutes: -2),
      last_login_ip: "127.0.0.2",
      confirmed_at: Timex.shift(Timex.now, minutes: -2)
    )

    insert(:user,
      id: 3,
      username: "ccc",
      name: "Ccc",
      email: "ccc@ccc.ccc",
      inserted_at: Timex.shift(Timex.now, minutes: -3),
      last_login_at: nil,
      last_login_ip: nil,
      confirmed_at: nil
    )

    assert [1, 2, 3] == User |> User.sort("creation") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("login") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("id") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("username") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("name") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("email") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [3, 2, 1] == User |> User.sort("inserted_at") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [2, 1, 3] == User |> User.sort("confirmed_at") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [2, 1, 3] == User |> User.sort("last_login_at") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("last_login_ip") |> Repo.all |> Enum.map(fn(u) -> u.id end)
  end

  test "sort/3" do
    insert(:user,
      id: 1,
      username: "aaa",
      name: "Aaa",
      email: "aaa@aaa.aaa",
      inserted_at: Timex.shift(Timex.now, minutes: -1),
      last_login_at: Timex.shift(Timex.now, minutes: -1),
      last_login_ip: "127.0.0.1",
      confirmed_at: Timex.shift(Timex.now, minutes: -1)
    )

    insert(:user,
      id: 2,
      username: "bbb",
      name: "Bbb",
      email: "bbb@bbb.bbb",
      inserted_at: Timex.shift(Timex.now, minutes: -2),
      last_login_at: Timex.shift(Timex.now, minutes: -2),
      last_login_ip: "127.0.0.2",
      confirmed_at: Timex.shift(Timex.now, minutes: -2)
    )

    insert(:user,
      id: 3,
      username: "ccc",
      name: "Ccc",
      email: "ccc@ccc.ccc",
      inserted_at: Timex.shift(Timex.now, minutes: -3),
      last_login_at: nil,
      last_login_ip: nil,
      confirmed_at: nil
    )

    assert [1, 2, 3] == User |> User.sort("id", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [3, 2, 1] == User |> User.sort("id", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("username", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [3, 2, 1] == User |> User.sort("username", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("name", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [3, 2, 1] == User |> User.sort("name", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("email", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [3, 2, 1] == User |> User.sort("email", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [3, 2, 1] == User |> User.sort("inserted_at", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("inserted_at", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [2, 1, 3] == User |> User.sort("confirmed_at", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("confirmed_at", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [2, 1, 3] == User |> User.sort("last_login_at", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("last_login_at", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [1, 2, 3] == User |> User.sort("last_login_ip", "asc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
    assert [2, 1, 3] == User |> User.sort("last_login_ip", "desc") |> Repo.all |> Enum.map(fn(u) -> u.id end)
  end

  test "verify!/2" do
    user = insert(:user, role: nil, verified_at: nil, verifier_id: nil)
    admin = insert(:user, role: "admin")
    {:ok, user} = User.verify!(user, admin)
    assert user.verified_at
    assert user.verifier_id == admin.id
    {:ok, time_diff, _, _} = Calendar.DateTime.diff(user.verified_at, DateTime.utc_now)
    assert time_diff < 10
  end

  test "unverify!/1" do
    admin = insert(:user, role: "admin")
    user = insert(:user, verified_at: Timex.now, verifier_id: admin.id)
    {:ok, user} = User.unverify!(user)
    refute user.verified_at
    refute user.verifier_id
  end

  test "verified?/1" do
    refute User.verified?(insert(:user, verified_at: nil))
    assert User.verified?(insert(:user, verified_at: Timex.now))
  end
end
