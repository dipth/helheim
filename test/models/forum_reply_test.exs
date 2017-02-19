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
end
