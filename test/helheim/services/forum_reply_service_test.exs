defmodule Helheim.ForumReplyServiceTest do
  use Helheim.DataCase
  import Mock
  alias Helheim.ForumReplyService
  alias Helheim.ForumReply
  alias Helheim.ForumTopic
  alias Helheim.NotificationService

  @valid_body "My Reply"
  @invalid_body ""

  ##############################################################################
  # create!/3
  describe "create/3 with valid user and body" do
    setup [:create_forum_topic, :create_user]

    test "creates a forum reply on the topic from the user with the specified body", %{forum_topic: forum_topic, user: user} do
      {:ok, %{forum_reply: forum_reply}} = ForumReplyService.create!(forum_topic, user, @valid_body)
      assert forum_reply.forum_topic_id == forum_topic.id
      assert forum_reply.user_id        == user.id
      assert forum_reply.body           == @valid_body
    end

    test "increments the forum_replies_count of the topic", %{forum_topic: forum_topic, user: user} do
      ForumReplyService.create!(forum_topic, user, @valid_body)
      forum_topic = Repo.get(ForumTopic, forum_topic.id)
      assert forum_topic.forum_replies_count == 1
    end

    test_with_mock "triggers notifications", %{forum_topic: forum_topic, user: user},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> {:ok, nil} end] do

      ForumReplyService.create!(forum_topic, user, @valid_body)
      assert called NotificationService.create_async!(:_, "forum_reply", forum_topic, user)
    end
  end

  describe "create/3 with invalid body" do
    setup [:create_forum_topic, :create_user]

    test "does not create any replies", %{forum_topic: forum_topic, user: user} do
      ForumReplyService.create!(forum_topic, user, @invalid_body)
      refute Repo.one(ForumReply)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{forum_topic: forum_topic, user: user} do
      {:error, failed_operation, failed_value, changes_so_far} = ForumReplyService.create!(forum_topic, user, @invalid_body)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end

    test "does not increment the forum_replies_count of the topic", %{forum_topic: forum_topic, user: user} do
      ForumReplyService.create!(forum_topic, user, @invalid_body)
      forum_topic = Repo.get(ForumTopic, forum_topic.id)
      assert forum_topic.forum_replies_count == 0
    end

    test_with_mock "does not trigger notifications", %{forum_topic: forum_topic, user: user},
      NotificationService, [], [create_async!: fn(_multi_changes, _type, _subject, _trigger_person) -> raise "NotificationService was called!" end] do

      ForumReplyService.create!(forum_topic, user, @invalid_body)
    end
  end

  defp create_forum_topic(_context), do: [forum_topic: insert(:forum_topic)]
end
