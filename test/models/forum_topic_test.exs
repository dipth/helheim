defmodule Helheim.ForumTopicTest do
  use Helheim.ModelCase
  alias Helheim.Repo
  alias Helheim.ForumTopic
  alias Helheim.Forum

  @valid_attrs %{title: "Foo", body: "Bar"}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = ForumTopic.changeset(%ForumTopic{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a title" do
      changeset = ForumTopic.changeset(%ForumTopic{}, Map.delete(@valid_attrs, :title))
      refute changeset.valid?
    end

    test "it requires a body" do
      changeset = ForumTopic.changeset(%ForumTopic{}, Map.delete(@valid_attrs, :body))
      refute changeset.valid?
    end

    test "it trims the title and body" do
      changeset = ForumTopic.changeset(%ForumTopic{}, Map.merge(@valid_attrs, %{title: "   Hello   ", body: "   World   "}))
      assert changeset.changes.title == "Hello"
      assert changeset.changes.body  == "World"
    end

    test "it increments the forum_topics_count of the associated forum" do
      forum     = insert(:forum)
      user      = insert(:user)
      forum
      |> Ecto.build_assoc(:forum_topics)
      |> ForumTopic.changeset(@valid_attrs)
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Repo.insert

      forum = Repo.get(Forum, forum.id)
      assert forum.forum_topics_count == 1
    end
  end

  describe "latest_over_forum/1" do
    test "it returns only the n latest topics for each forum" do
      forum_1 = insert(:forum)
      forum_2 = insert(:forum)
      forum_1_topic_1 = insert(:forum_topic, forum: forum_1)
      forum_1_topic_2 = insert(:forum_topic, forum: forum_1)
      forum_1_topic_3 = insert(:forum_topic, forum: forum_1)
      forum_2_topic_1 = insert(:forum_topic, forum: forum_2)
      forum_2_topic_2 = insert(:forum_topic, forum: forum_2)
      forum_2_topic_3 = insert(:forum_topic, forum: forum_2)

      forum_topics = ForumTopic.latest_over_forum(2) |> Repo.all

      refute Enum.find(forum_topics, fn(t) -> t.id == forum_1_topic_1.id end)
      assert Enum.find(forum_topics, fn(t) -> t.id == forum_1_topic_2.id end)
      assert Enum.find(forum_topics, fn(t) -> t.id == forum_1_topic_3.id end)
      refute Enum.find(forum_topics, fn(t) -> t.id == forum_2_topic_1.id end)
      assert Enum.find(forum_topics, fn(t) -> t.id == forum_2_topic_2.id end)
      assert Enum.find(forum_topics, fn(t) -> t.id == forum_2_topic_3.id end)
    end
  end

  describe "with_latest_reply/1" do
    test "it preloads the latest reply for each topic" do
      topic_1 = insert(:forum_topic)
      topic_2 = insert(:forum_topic)
      _topic_1_reply_1 = insert(:forum_reply, forum_topic: topic_1)
       topic_1_reply_2 = insert(:forum_reply, forum_topic: topic_1)
      _topic_2_reply_1 = insert(:forum_reply, forum_topic: topic_2)
       topic_2_reply_2 = insert(:forum_reply, forum_topic: topic_2)

      topics = ForumTopic |> ForumTopic.with_latest_reply |> Repo.all
      topic_1 = Enum.find(topics, fn(t) -> t.id == topic_1.id end)
      topic_2 = Enum.find(topics, fn(t) -> t.id == topic_2.id end)
      assert Enum.map(topic_1.forum_replies, fn(r) -> r.id end) == [topic_1_reply_2.id]
      assert Enum.map(topic_2.forum_replies, fn(r) -> r.id end) == [topic_2_reply_2.id]
    end
  end
end
