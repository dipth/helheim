defmodule Helheim.IgnoreTest do
  use Helheim.DataCase
  alias Helheim.Ignore

  ##############################################################################
  # for_ignorer/2
  describe "for_ignorer/2" do
    test "finds only ignores created by the given user" do
      user_1    = insert(:user)
      user_2    = insert(:user)
      ignore_1  = insert(:ignore, ignorer: user_1)
      _ignore_2 = insert(:ignore, ignorer: user_2)
      [ignore]  = Ignore |> Ignore.for_ignorer(user_1) |> Repo.all
      assert ignore.id == ignore_1.id
    end
  end

  ##############################################################################
  # for_ignoree/2
  describe "for_ignoree/2" do
    test "finds only ignores created against the given user" do
      user_1    = insert(:user)
      user_2    = insert(:user)
      ignore_1  = insert(:ignore, ignoree: user_1)
      _ignore_2 = insert(:ignore, ignoree: user_2)
      [ignore]  = Ignore |> Ignore.for_ignoree(user_1) |> Repo.all
      assert ignore.id == ignore_1.id
    end
  end

  ##############################################################################
  # involving_user/2
  describe "involving_user/2" do
    test "finds only ignores created by or against the given user" do
      user     = insert(:user)
      ignore_1 = insert(:ignore, ignoree: user)
      ignore_2 = insert(:ignore, ignoree: user)
      ignore_3 = insert(:ignore)
      ignore_ids = Ignore |> Ignore.involving_user(user) |> Repo.all |> Enum.map(&(&1.id))
      assert Enum.member?(ignore_ids, ignore_1.id)
      assert Enum.member?(ignore_ids, ignore_2.id)
      refute Enum.member?(ignore_ids, ignore_3.id)
    end
  end

  ##############################################################################
  # order_by_ignorer_and_ignoree_username/2
  describe "order_by_ignorer_and_ignoree_username/2" do
    test "orders the ignores first by the username of the associated ignorer and then by the username of the ignoree" do
      user_1   = insert(:user, username: "Adam")
      user_2   = insert(:user, username: "Bob")
      user_3   = insert(:user, username: "Charlie")
      ignore_1 = insert(:ignore, ignorer: user_1, ignoree: user_2)
      ignore_2 = insert(:ignore, ignorer: user_1, ignoree: user_3)
      ignore_3 = insert(:ignore, ignorer: user_2, ignoree: user_3)
      ignore_4 = insert(:ignore, ignorer: user_2, ignoree: user_1)
      ignore_ids = Ignore |> Ignore.order_by_ignorer_and_ignoree_username() |> Repo.all |> Enum.map(&(&1.id))
      assert [ignore_1.id, ignore_2.id, ignore_4.id, ignore_3.id] == ignore_ids
    end
  end

  ##############################################################################
  # order_by_ignoree_username/2
  describe "order_by_ignoree_username/2" do
    test "orders the ignores by the username of the associated ignoree" do
      user_1   = insert(:user, username: "Adam")
      user_2   = insert(:user, username: "Bob")
      ignore_1 = insert(:ignore, ignoree: user_2)
      ignore_2 = insert(:ignore, ignoree: user_1)
      ignores  = Ignore |> Ignore.order_by_ignoree_username() |> Repo.all
      ids      = Enum.map ignores, fn(c) -> c.id end
      assert [ignore_2.id, ignore_1.id] == ids
    end
  end

  ##############################################################################
  # enabled/1
  describe "enabled/1" do
    test "finds only enabled ignores" do
      ignore_1  = insert(:ignore, enabled: true)
      _ignore_2 = insert(:ignore, enabled: false)
      [ignore]  = Ignore |> Ignore.enabled() |> Repo.all
      assert ignore.id == ignore_1.id
    end
  end

  ##############################################################################
  # ignored?/2
  describe "ignored?/2" do
    test "returns true if an enabled ignore exists with the given ignorer and ignoree" do
      ignore = insert(:ignore, enabled: true)
      assert Ignore.ignored?(ignore.ignorer, ignore.ignoree)
    end

    test "returns false if no enabled ignore exists with the given ignorer and ignoree" do
      ignore = insert(:ignore, enabled: false)
      refute Ignore.ignored?(ignore.ignorer, ignore.ignoree)
    end

    test "returns false if no ignore exists with the given ignorer" do
      ignore = insert(:ignore, enabled: true)
      refute Ignore.ignored?(insert(:user), ignore.ignoree)
    end

    test "returns false if no ignore exists with the given ignoree" do
      ignore = insert(:ignore, enabled: true)
      refute Ignore.ignored?(ignore.ignorer, insert(:user))
    end

    test "allows passing a user id instead of a user as ignorer" do
      ignore = insert(:ignore, enabled: true)
      assert Ignore.ignored?(ignore.ignorer_id, ignore.ignoree)
    end
  end

  ##############################################################################
  # ignore!/2
  describe "ignore!/2" do
    test "creates a new ignore for the specified users" do
      ignorer      = insert(:user)
      ignoree      = insert(:user)
      {:ok, ignore} = Ignore.ignore!(ignorer, ignoree)
      assert ignore.id
      assert ignore.ignorer_id == ignorer.id
      assert ignore.ignoree_id == ignoree.id
      assert ignore.enabled
    end

    test "it updates an existing ignore if there is one" do
      existing_ignore = insert(:ignore, enabled: false)
      ignorer         = existing_ignore.ignorer
      ignoree         = existing_ignore.ignoree
      {:ok, ignore}   = Ignore.ignore!(ignorer, ignoree)
      assert ignore.id         == existing_ignore.id
      assert ignore.ignorer_id == ignorer.id
      assert ignore.ignoree_id == ignoree.id
      assert ignore.enabled
    end

    test "it returns an error when ignorer and ignoree is the same user" do
      user        = insert(:user)
      {:error, _} = Ignore.ignore!(user, user)
    end
  end

  ##############################################################################
  # unignore!/2
  describe "unignore!/2" do
    test "creates a new ignore for the specified users" do
      ignorer       = insert(:user)
      ignoree       = insert(:user)
      {:ok, ignore} = Ignore.unignore!(ignorer, ignoree)
      assert ignore.id
      assert ignore.ignorer_id == ignorer.id
      assert ignore.ignoree_id == ignoree.id
      refute ignore.enabled
    end

    test "it updates an existing ignore if there is one" do
      existing_ignore = insert(:ignore, enabled: true)
      ignorer         = existing_ignore.ignorer
      ignoree         = existing_ignore.ignoree
      {:ok, ignore}   = Ignore.unignore!(ignorer, ignoree)
      assert ignore.id         == existing_ignore.id
      assert ignore.ignorer_id == ignorer.id
      assert ignore.ignoree_id == ignoree.id
      refute ignore.enabled
    end

    test "it returns an error when ignorer and ignoree is the same user" do
      user        = insert(:user)
      {:error, _} = Ignore.unignore!(user, user)
    end
  end

  ##############################################################################
  # get_ignore_map/0
  describe "get_ignore_map/0" do
    test "it returns a map with lists of user ids that are ignored by the user with the id of the given key" do
      user_1 = insert(:user, id: 1)
      user_2 = insert(:user, id: 2)
      user_3 = insert(:user, id: 3)
      insert(:ignore, ignorer: user_1, ignoree: user_2)
      insert(:ignore, ignorer: user_1, ignoree: user_3)
      insert(:ignore, ignorer: user_2, ignoree: user_3)

      assert Ignore.get_ignore_map == %{1 => [2,3], 2 => [3]}
    end

    test "it does not include disabled ignores" do
      insert(:ignore, enabled: false)
      assert Ignore.get_ignore_map == %{}
    end
  end
end
