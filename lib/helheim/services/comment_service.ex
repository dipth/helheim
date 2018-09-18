defmodule Helheim.CommentService do
  import Ecto.Query
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Comment
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.Photo
  alias Helheim.CalendarEvent
  alias Helheim.NotificationService

  def create!(commentable, author, body) do
    Multi.new
    |> insert_comment(commentable, author, body)
    |> inc_comment_count(commentable)
    |> trigger_notifications(commentable, author)
    |> Repo.transaction
  end

  def delete!(comment, user, reason \\ "") do
    Multi.new
    |> ensure_deletable(comment, user)
    |> delete_comment(comment, user, reason)
    |> dec_comment_count(Comment.commentable(comment))
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

  defp put_commentable(changeset, %User{} = profile),                 do: Changeset.put_assoc(changeset, :profile, profile)
  defp put_commentable(changeset, %BlogPost{} = blog_post),           do: Changeset.put_assoc(changeset, :blog_post, blog_post)
  defp put_commentable(changeset, %Photo{} = photo),                  do: Changeset.put_assoc(changeset, :photo, photo)
  defp put_commentable(changeset, %CalendarEvent{} = calendar_event), do: Changeset.put_assoc(changeset, :calendar_event, calendar_event)

  defp inc_comment_count(multi, %User{} = profile),                 do: inc_comment_count(multi, User, profile.id)
  defp inc_comment_count(multi, %BlogPost{} = blog_post),           do: inc_comment_count(multi, BlogPost, blog_post.id)
  defp inc_comment_count(multi, %Photo{} = photo),                  do: inc_comment_count(multi, Photo, photo.id)
  defp inc_comment_count(multi, %CalendarEvent{} = calendar_event), do: inc_comment_count(multi, CalendarEvent, calendar_event.id)
  defp inc_comment_count(multi, model, id) do
    multi |> Multi.update_all(:comment_count, (model |> where(id: ^id)), inc: [comment_count: 1])
  end

  defp dec_comment_count(multi, %User{} = profile),                 do: dec_comment_count(multi, User, profile.id)
  defp dec_comment_count(multi, %BlogPost{} = blog_post),           do: dec_comment_count(multi, BlogPost, blog_post.id)
  defp dec_comment_count(multi, %Photo{} = photo),                  do: dec_comment_count(multi, Photo, photo.id)
  defp dec_comment_count(multi, %CalendarEvent{} = calendar_event), do: dec_comment_count(multi, CalendarEvent, calendar_event.id)
  defp dec_comment_count(multi, model, id) do
    multi |> Multi.update_all(:comment_count, (model |> where(id: ^id)), inc: [comment_count: -1])
  end

  defp trigger_notifications(multi, commentable, author) do
    multi |> Multi.run(:notify, NotificationService, :create_async!, ["comment", commentable, author])
  end

  defp ensure_deletable(multi, comment, user), do: Multi.run(multi, :ensure_deletable, fn(_) -> ensure_deletable(comment, user) end)
  defp ensure_deletable(comment, user) do
    case Comment.deletable_by?(comment, user) do
      true  -> {:ok, nil}
      false -> {:error, "Comment not deletable by user!"}
    end
  end

  defp delete_comment(multi, comment, user, reason) do
    multi
    |> Multi.update(:comment, Comment.delete_changeset(comment, user, %{deletion_reason: reason}))
  end
end
