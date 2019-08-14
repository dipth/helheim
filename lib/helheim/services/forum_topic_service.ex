defmodule Helheim.ForumTopicService do
  alias Helheim.NotificationSubscription
  alias Helheim.Repo

  def create!(user, changeset) do
    with {:ok, topic} <- create_topic(changeset),
         {:ok, _sub} <- create_notification_subscription(user, topic)
    do
      {:ok, topic}
    end
  end

  defp create_topic(changeset) do
    changeset
    |> Repo.insert()
  end

  defp create_notification_subscription(user, topic) do
    NotificationSubscription.enable!(user, "forum_reply", topic)
  end
end
