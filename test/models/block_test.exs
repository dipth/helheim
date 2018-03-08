defmodule Helheim.BlockTest do
  use Helheim.ModelCase
  alias Helheim.Block

  ##############################################################################
  # for_blocker/2
  describe "for_blocker/2" do
    test "finds only blocks created by the given user" do
      user_1   = insert(:user)
      user_2   = insert(:user)
      block_1  = insert(:block, blocker: user_1)
      _block_2 = insert(:block, blocker: user_2)
      [block]  = Block |> Block.for_blocker(user_1) |> Repo.all
      assert block.id == block_1.id
    end
  end

  ##############################################################################
  # for_blockee/2
  describe "for_blockee/2" do
    test "finds only blocks created against the given user" do
      user_1   = insert(:user)
      user_2   = insert(:user)
      block_1  = insert(:block, blockee: user_1)
      _block_2 = insert(:block, blockee: user_2)
      [block]  = Block |> Block.for_blockee(user_1) |> Repo.all
      assert block.id == block_1.id
    end
  end

  ##############################################################################
  # involving_user/2
  describe "involving_user/2" do
    test "finds only blocks created by or against the given user" do
      user    = insert(:user)
      block_1 = insert(:block, blockee: user)
      block_2 = insert(:block, blockee: user)
      block_3 = insert(:block)
      block_ids = Block |> Block.involving_user(user) |> Repo.all |> Enum.map(&(&1.id))
      assert Enum.member?(block_ids, block_1.id)
      assert Enum.member?(block_ids, block_2.id)
      refute Enum.member?(block_ids, block_3.id)
    end
  end

  ##############################################################################
  # order_by_blocker_and_blockee_username/2
  describe "order_by_blocker_and_blockee_username/2" do
    test "orders the blocks first by the username of the associated blocker and then by the username of the blockee" do
      user_1  = insert(:user, username: "Adam")
      user_2  = insert(:user, username: "Bob")
      user_3  = insert(:user, username: "Charlie")
      block_1 = insert(:block, blocker: user_1, blockee: user_2)
      block_2 = insert(:block, blocker: user_1, blockee: user_3)
      block_3 = insert(:block, blocker: user_2, blockee: user_3)
      block_4 = insert(:block, blocker: user_2, blockee: user_1)
      block_ids = Block |> Block.order_by_blocker_and_blockee_username() |> Repo.all |> Enum.map(&(&1.id))
      assert [block_1.id, block_2.id, block_4.id, block_3.id] == block_ids
    end
  end

  ##############################################################################
  # order_by_blockee_username/2
  describe "order_by_blockee_username/2" do
    test "orders the blocks by the username of the associated blockee" do
      user_1  = insert(:user, username: "Adam")
      user_2  = insert(:user, username: "Bob")
      block_1 = insert(:block, blockee: user_2)
      block_2 = insert(:block, blockee: user_1)
      blocks  = Block |> Block.order_by_blockee_username() |> Repo.all
      ids     = Enum.map blocks, fn(c) -> c.id end
      assert [block_2.id, block_1.id] == ids
    end
  end

  ##############################################################################
  # enabled/1
  describe "enabled/1" do
    test "finds only enabled blocks" do
      block_1  = insert(:block, enabled: true)
      _block_2 = insert(:block, enabled: false)
      [block]  = Block |> Block.enabled() |> Repo.all
      assert block.id == block_1.id
    end
  end

  ##############################################################################
  # blocked?/2
  describe "blocked?/2" do
    test "returns true if an enabled block exists with the given blocker and blockee" do
      block = insert(:block, enabled: true)
      assert Block.blocked?(block.blocker, block.blockee)
    end

    test "returns false if no enabled block exists with the given blocker and blockee" do
      block = insert(:block, enabled: false)
      refute Block.blocked?(block.blocker, block.blockee)
    end

    test "returns false if no block exists with the given blocker" do
      block = insert(:block, enabled: true)
      refute Block.blocked?(insert(:user), block.blockee)
    end

    test "returns false if no block exists with the given blockee" do
      block = insert(:block, enabled: true)
      refute Block.blocked?(block.blocker, insert(:user))
    end

    test "allows passing a user id instead of a user as blocker" do
      block = insert(:block, enabled: true)
      assert Block.blocked?(block.blocker_id, block.blockee)
    end
  end

  ##############################################################################
  # block!/2
  describe "block!/2" do
    test "creates a new block for the specified users" do
      blocker      = insert(:user)
      blockee      = insert(:user)
      {:ok, block} = Block.block!(blocker, blockee)
      assert block.id
      assert block.blocker_id == blocker.id
      assert block.blockee_id == blockee.id
      assert block.enabled
    end

    test "it updates an existing block if there is one" do
      existing_block = insert(:block, enabled: false)
      blocker        = existing_block.blocker
      blockee        = existing_block.blockee
      {:ok, block}   = Block.block!(blocker, blockee)
      assert block.id         == existing_block.id
      assert block.blocker_id == blocker.id
      assert block.blockee_id == blockee.id
      assert block.enabled
    end

    test "it returns an error when blocker and blockee is the same user" do
      user        = insert(:user)
      {:error, _} = Block.block!(user, user)
    end
  end

  ##############################################################################
  # unblock!/2
  describe "unblock!/2" do
    test "creates a new block for the specified users" do
      blocker      = insert(:user)
      blockee      = insert(:user)
      {:ok, block} = Block.unblock!(blocker, blockee)
      assert block.id
      assert block.blocker_id == blocker.id
      assert block.blockee_id == blockee.id
      refute block.enabled
    end

    test "it updates an existing block if there is one" do
      existing_block = insert(:block, enabled: true)
      blocker        = existing_block.blocker
      blockee        = existing_block.blockee
      {:ok, block}   = Block.unblock!(blocker, blockee)
      assert block.id         == existing_block.id
      assert block.blocker_id == blocker.id
      assert block.blockee_id == blockee.id
      refute block.enabled
    end

    test "it returns an error when blocker and blockee is the same user" do
      user        = insert(:user)
      {:error, _} = Block.unblock!(user, user)
    end
  end
end
