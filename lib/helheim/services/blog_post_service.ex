defmodule Helheim.BlogPostService do
  alias Helheim.BlogPost
  alias Helheim.NotificationSubscription
  alias Helheim.Repo

  def create!(author, params) do
    with {:ok, blog} <- create_blog(author, params),
         {:ok, _sub} <- create_notification_subscription(author, blog)
    do
      {:ok, blog}
    end
  end

  defp create_blog(author, params) do
    author
    |> Ecto.build_assoc(:blog_posts)
    |> BlogPost.changeset(params)
    |> Repo.insert()
  end

  defp create_notification_subscription(author, blog) do
    NotificationSubscription.enable!(author, "comment", blog)
  end
end
