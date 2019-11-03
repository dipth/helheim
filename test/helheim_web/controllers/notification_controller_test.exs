defmodule HelheimWeb.NotificationControllerTest do
  use HelheimWeb.ConnCase
  use Helheim.AssertCalledPatternMatching
  import Mock
  alias Helheim.Notification
  alias Helheim.NotificationService

  ##############################################################################
  # show/2
  describe "show/2 when signed in" do
    setup [:create_and_sign_in_user]

    test "it redirects to the profile comments page when the subject of the notification is a profile", %{conn: conn, user: user} do
      subject      = insert(:user)
      notification = insert(:notification, recipient: user)
      with_mock Notification, [:passthrough], [subject: fn(_notification) -> subject end] do
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) == public_profile_comment_path(conn, :index, subject)
      end
    end

    test "it redirects to the blog post page when the subject of the notification is a blog post", %{conn: conn, user: user} do
      subject      = insert(:blog_post)
      notification = insert(:notification, recipient: user)
      with_mock Notification, [:passthrough], [subject: fn(_notification) -> subject end] do
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) == public_profile_blog_post_path(conn, :show, subject.user, subject)
      end
    end

    test "it redirects to the photo album page when the subject of the notification is a photo album", %{conn: conn, user: user} do
      subject      = insert(:photo_album)
      notification = insert(:notification, recipient: user)
      with_mock Notification, [:passthrough], [subject: fn(_notification) -> subject end] do
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) == public_profile_photo_album_path(conn, :show, subject.user, subject)
      end
    end

    test "it redirects to the photo page when the subject of the notification is a photo", %{conn: conn, user: user} do
      subject      = insert(:photo)
      notification = insert(:notification, recipient: user)
      with_mock Notification, [:passthrough], [subject: fn(_notification) -> subject end] do
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) == public_profile_photo_album_photo_path(conn, :show, subject.photo_album.user, subject.photo_album, subject)
      end
    end

    test "it redirects to the forum topic page when the subject of the notification is a forum topic", %{conn: conn, user: user} do
      subject      = insert(:forum_topic)
      notification = insert(:notification, recipient: user)
      with_mock Notification, [:passthrough], [subject: fn(_notification) -> subject end] do
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) == forum_forum_topic_path(conn, :show, subject.forum, subject, page: "last") <> "#last_reply"
      end
    end

    test "it redirects to the calendar_event page when the subject of the notification is a calendar_event", %{conn: conn, user: user} do
      subject      = insert(:calendar_event)
      notification = insert(:notification, recipient: user)
      with_mock Notification, [:passthrough], [subject: fn(_notification) -> subject end] do
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) == calendar_event_path(conn, :show, subject)
      end
    end

    test "it marks the notification as clicked", %{conn: conn, user: user} do
      with_mocks([
        {Notification, [:passthrough], [subject: fn(_notification) -> insert(:user) end]},
        {NotificationService, [], [mark_as_clicked!: fn(_notification) -> {:ok, %Notification{}} end]}
      ]) do
        notification = insert(:notification, recipient: user)
        get conn, "/notifications/#{notification.id}"

        assert_called_with_pattern NotificationService, :mark_as_clicked!, fn(args) ->
          notification_id = notification.id
          [%Notification{id: ^notification_id}] = args
        end
      end
    end

    test "it does not mark the notification as clicked but instead shows an error page if the notification does not belong to the current user", %{conn: conn} do
      with_mocks([
        {Notification, [:passthrough], [subject: fn(_notification) -> insert(:user) end]},
        {NotificationService, [], [mark_as_clicked!: fn(_notification) -> raise("NotificationService was called!") end]}
      ]) do
        notification = insert(:notification)
        assert_error_sent :not_found, fn ->
          get conn, "/notifications/#{notification.id}"
        end
      end
    end
  end

  describe "show/2 when not signed in" do
    test "it does not mark the notification as clicked bute instead redirects to the sign in page", %{conn: conn} do
      with_mocks([
        {Notification, [:passthrough], [subject: fn(_notification) -> insert(:user) end]},
        {NotificationService, [], [mark_as_clicked!: fn(_notification) -> raise("NotificationService was called!") end]}
      ]) do
        notification = insert(:notification)
        conn = get conn, "/notifications/#{notification.id}"
        assert redirected_to(conn) =~ session_path(conn, :new)
      end
    end
  end
end
