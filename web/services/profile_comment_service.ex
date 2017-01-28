defmodule Helheim.ProfileCommentService do
  import Helheim.Gettext
  import Helheim.Router.Helpers
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Comment
  alias Helheim.Notification

  def insert(attrs, author, profile) do
    Multi.new
    |> Multi.insert(:comment, build_comment(attrs, author, profile))
    |> maybe_insert_notification(author, profile)
    |> Repo.transaction
  end

  defp build_comment(attrs, author, profile) do
    Comment.changeset(%Comment{}, attrs)
    |> Ecto.Changeset.put_assoc(:author, author)
    |> Ecto.Changeset.put_assoc(:profile, profile)
  end

  defp maybe_insert_notification(multi, author, profile) do
    if author.id != profile.id do
      multi
      |> Multi.insert(:notification, build_notification(author, profile))
    else
      multi
    end
  end

  defp build_notification(author, profile) do
    attrs = %{
      title: gettext("%{username} wrote a comment in your guest book", username: author.username),
      icon:  "comment-o",
      path:  public_profile_comment_path(Helheim.Endpoint, :index, profile.id)
    }
    Notification.changeset(%Notification{}, attrs)
    |> Ecto.Changeset.put_assoc(:user, profile)
  end
end
