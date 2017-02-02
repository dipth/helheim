defmodule Helheim.BlogPostCommentService do
  import Helheim.Gettext
  import Helheim.Router.Helpers
  alias Ecto.Multi
  alias Helheim.Repo
  alias Helheim.Comment
  alias Helheim.NotificationService

  def insert(attrs, author, blog_post) do
    Multi.new
    |> Multi.insert(:comment, build_comment(attrs, author, blog_post))
    |> maybe_insert_notification(author, blog_post)
    |> Repo.transaction
  end

  defp build_comment(attrs, author, blog_post) do
    Comment.changeset(%Comment{}, attrs)
    |> Ecto.Changeset.put_assoc(:author, author)
    |> Ecto.Changeset.put_assoc(:blog_post, blog_post)
  end

  defp maybe_insert_notification(multi, author, blog_post) do
    if author.id != blog_post.user.id do
      multi
      |> Multi.append(build_notification(author, blog_post))
    else
      multi
    end
  end

  defp build_notification(author, blog_post) do
    attrs = %{
      title: gettext("%{username} wrote a comment on your blog post: %{title}", username: author.username, title: blog_post.title),
      icon:  "comment-o",
      path:  public_profile_blog_post_path(Helheim.Endpoint, :show, blog_post.user.id, blog_post.id)
    }
    NotificationService.multi_insert(blog_post.user, attrs)
  end
end
