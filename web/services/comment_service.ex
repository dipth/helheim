defmodule Helheim.CommentService do
  import Ecto.Query
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Comment
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Photo
  alias Helheim.NotificationService

  def create!(commentable, author, body) do
    Multi.new
    |> insert_comment(commentable, author, body)
    |> inc_comment_count(commentable)
    |> trigger_notifications(commentable, author)
    |> Repo.transaction
  end

  defp insert_comment(multi, commentable, author, body) do
    multi
    |> Multi.insert(:comment, build_comment(commentable, author, body))
  end

  defp build_comment(commentable, author, body) do
    Comment.changeset(%Comment{}, %{body: body})
    |> Changeset.put_assoc(:author, author)
    |> put_commentable(commentable)
  end

  defp put_commentable(changeset, %User{} = profile),       do: Changeset.put_assoc(changeset, :profile, profile)
  defp put_commentable(changeset, %BlogPost{} = blog_post), do: Changeset.put_assoc(changeset, :blog_post, blog_post)
  defp put_commentable(changeset, %Photo{} = photo),        do: Changeset.put_assoc(changeset, :photo, photo)

  defp inc_comment_count(multi, %User{} = profile),       do: inc_comment_count(multi, User, profile.id)
  defp inc_comment_count(multi, %BlogPost{} = blog_post), do: inc_comment_count(multi, BlogPost, blog_post.id)
  defp inc_comment_count(multi, %Photo{} = photo),        do: inc_comment_count(multi, Photo, photo.id)
  defp inc_comment_count(multi, model, id) do
    multi |> Multi.update_all(:comment_count, (model |> where(id: ^id)), inc: [comment_count: 1])
  end

  defp trigger_notifications(multi, commentable, author) do
    multi |> Multi.run(:notify, NotificationService, :create_async!, ["comment", commentable, author])
  end
end
