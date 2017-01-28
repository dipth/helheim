defmodule Helheim.ProfileCommentServiceTest do
  use Helheim.ModelCase
  import Helheim.Router.Helpers
  alias Helheim.ProfileCommentService
  alias Helheim.Comment
  alias Helheim.Notification

  @valid_attrs %{ body: "Foo Bar" }
  @invalid_attrs %{ body: "   " }

  describe "insert/3 with valid attrs, author and profile" do
    setup [:create_author_and_profile]

    test "creates a comment on the profile from the author with the attrs", %{author: author, profile: profile} do
      ProfileCommentService.insert(@valid_attrs, author, profile)
      comment = Repo.get_by(Comment, @valid_attrs)
      assert comment.author_id == author.id
      assert comment.profile_id == profile.id
    end

    test "creates a notification for the profile", %{author: author, profile: profile} do
      ProfileCommentService.insert(@valid_attrs, author, profile)
      notification = Repo.one(Notification)
      assert notification.user_id == profile.id
      assert notification.title == gettext("%{username} wrote a comment in your guest book", username: author.username)
      assert notification.path == public_profile_comment_path(Helheim.Endpoint, :index, profile.id)
    end

    test "does not create a notification if the author is the same as the profile", %{author: author} do
      ProfileCommentService.insert(@valid_attrs, author, author)
      refute Repo.one(Notification)
    end

    test "returns :ok and a Map including a comment and a notification", %{author: author, profile: profile} do
      {:ok, %{comment: comment, notification: notification}} = ProfileCommentService.insert(@valid_attrs, author, profile)
      assert comment
      assert notification
    end

    test "it does not allow spoofing the author", %{author: author, profile: profile} do
      ProfileCommentService.insert(Map.merge(@valid_attrs, %{author_id: profile.id}), author, profile)
      comment = Repo.one(Comment)
      assert comment.author_id == author.id
    end

    test "it trims whitespace from the body", %{author: author, profile: profile} do
      ProfileCommentService.insert(Map.merge(@valid_attrs, %{body: "   Foo   "}), author, profile)
      comment = Repo.one(Comment)
      assert comment.body == "Foo"
    end
  end

  describe "insert/3 with invalid attrs" do
    setup [:create_author_and_profile]

    test "does not create any comments", %{author: author, profile: profile} do
      ProfileCommentService.insert(@invalid_attrs, author, profile)
      refute Repo.one(Comment)
    end

    test "does not create any notifications", %{author: author, profile: profile} do
      ProfileCommentService.insert(@invalid_attrs, author, profile)
      refute Repo.one(Notification)
    end

    test "returns :error, the failed operation, the failed value and changes so far", %{author: author, profile: profile} do
      {:error, failed_operation, failed_value, changes_so_far} = ProfileCommentService.insert(@invalid_attrs, author, profile)
      assert failed_operation
      assert failed_value
      assert changes_so_far
    end
  end

  defp create_author_and_profile(_context) do
    author  = insert(:user)
    profile = insert(:user)
    [author: author, profile: profile]
  end
end
