defmodule Helheim.ForumReplyTest do
  use Helheim.ModelCase
  alias Helheim.Repo
  alias Helheim.ForumReply
  alias Helheim.ForumTopic

  @valid_attrs %{body: "Bar"}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = ForumReply.changeset(%ForumReply{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a body" do
      changeset = ForumReply.changeset(%ForumReply{}, Map.delete(@valid_attrs, :body))
      refute changeset.valid?
    end

    test "it trims the body" do
      changeset = ForumReply.changeset(%ForumReply{}, Map.merge(@valid_attrs, %{body: "   Foo   "}))
      assert changeset.changes.body  == "Foo"
    end

    test "it increments the forum_replies_count and updates the updated_at of the associated forum_topic" do
      forum_topic = insert(:forum_topic)
      user        = insert(:user)
      updated_at  = forum_topic.updated_at

      forum_topic
      |> Ecto.build_assoc(:forum_replies)
      |> ForumReply.changeset(@valid_attrs)
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert

      forum_topic = Repo.get(ForumTopic, forum_topic.id)
      assert forum_topic.forum_replies_count == 1
      assert forum_topic.updated_at > updated_at
    end
  end

  describe "latest_over_forum_topic/1" do
    test "it returns only the n latest topics for each forum" do
      topic_1 = insert(:forum_topic)
      topic_2 = insert(:forum_topic)
      topic_1_reply_1 = insert(:forum_reply, forum_topic: topic_1)
      topic_1_reply_2 = insert(:forum_reply, forum_topic: topic_1)
      topic_1_reply_3 = insert(:forum_reply, forum_topic: topic_1)
      topic_2_reply_1 = insert(:forum_reply, forum_topic: topic_2)
      topic_2_reply_2 = insert(:forum_reply, forum_topic: topic_2)
      topic_2_reply_3 = insert(:forum_reply, forum_topic: topic_2)

      forum_replies = ForumReply.latest_over_forum_topic(2) |> Repo.all

      refute Enum.find(forum_replies, fn(t) -> t.id == topic_1_reply_1.id end)
      assert Enum.find(forum_replies, fn(t) -> t.id == topic_1_reply_2.id end)
      assert Enum.find(forum_replies, fn(t) -> t.id == topic_1_reply_3.id end)
      refute Enum.find(forum_replies, fn(t) -> t.id == topic_2_reply_1.id end)
      assert Enum.find(forum_replies, fn(t) -> t.id == topic_2_reply_2.id end)
      assert Enum.find(forum_replies, fn(t) -> t.id == topic_2_reply_3.id end)
    end
  end

  describe "editable_by?/2" do
    test "it returns true if the user is the author of the topic and it is no older than 60 minutes" do
      user  = insert(:user)
      reply = insert(:forum_reply, user: user, inserted_at: Timex.shift(Timex.now, minutes: -59))
      assert ForumReply.editable_by?(reply, user)
    end

    test "it returns false if the topic is older than 60 minutes" do
      user  = insert(:user)
      reply = insert(:forum_reply, user: user, inserted_at: Timex.shift(Timex.now, minutes: -61))
      refute ForumReply.editable_by?(reply, user)
    end

    test "it returns false if the user is not the author of the topic" do
      user  = insert(:user)
      reply = insert(:forum_reply, inserted_at: Timex.shift(Timex.now, minutes: -9))
      refute ForumReply.editable_by?(reply, user)
    end

    test "it returns true if the user is an admin" do
      user  = insert(:user, role: "admin")
      reply = insert(:forum_reply, inserted_at: Timex.shift(Timex.now, minutes: -11))
      assert ForumReply.editable_by?(reply, user)
    end
  end

  describe "in_order/1" do
    test "it orders recently inserted replies after older ones" do
      forum_reply1 = insert(:forum_reply, inserted_at: Timex.shift(Timex.now, minutes: 5))
      forum_reply2 = insert(:forum_reply)
      [first, last] = ForumReply |> ForumReply.in_order |> Repo.all
      assert first.id == forum_reply2.id
      assert last.id == forum_reply1.id
    end
  end

  describe "newest/1" do
    test "orders replies by descending inserted_at" do
      reply1 = insert(:forum_reply, inserted_at: Timex.shift(Timex.now, minutes: -1))
      reply2 = insert(:forum_reply, inserted_at: Timex.shift(Timex.now, minutes: -2))
      replies = ForumReply |> ForumReply.newest |> Repo.all
      ids        = Enum.map replies, fn(c) -> c.id end
      assert [reply1.id, reply2.id] == ids
    end
  end
end
