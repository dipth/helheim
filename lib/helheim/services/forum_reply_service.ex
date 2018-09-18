defmodule Helheim.ForumReplyService do
  import Ecto.Query
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.ForumReply
  alias Helheim.ForumTopic
  alias Helheim.NotificationService

  def create!(forum_topic, user, body) do
    Multi.new
    |> insert_reply(forum_topic, user, body)
    |> inc_forum_replies_count(forum_topic)
    |> trigger_notifications(forum_topic, user)
    |> Repo.transaction
  end

  defp insert_reply(multi, forum_topic, user, body) do
    multi
    |> Multi.insert(:forum_reply, build_reply(forum_topic, user, body))
  end

  defp build_reply(forum_topic, user, body) do
    ForumReply.changeset(%ForumReply{}, %{body: body})
    |> Changeset.put_assoc(:forum_topic, forum_topic)
    |> Changeset.put_assoc(:user, user)
  end

  defp inc_forum_replies_count(multi, forum_topic) do
    multi |> Multi.update_all(:forum_replies_count, (ForumTopic |> where(id: ^forum_topic.id)), inc: [forum_replies_count: 1])
  end

  defp trigger_notifications(multi, forum_topic, user) do
    multi |> Multi.run(:notify, NotificationService, :create_async!, ["forum_reply", forum_topic, user])
  end
end
