defmodule Helheim.NotificationSubscription do
  use Helheim.Web, :model
  import Ecto.Changeset
  alias Helheim.Repo
  alias Helheim.NotificationSubscription
  alias Helheim.User
  alias Helheim.BlogPost
  alias Helheim.ForumTopic
  alias Helheim.Photo
  alias Helheim.CalendarEvent

  @types ["comment", "blog_post", "photo", "forum_reply", "calendar_event"]
  def types, do: @types

  schema "notification_subscriptions" do
    field :type,    :string
    field :enabled, :boolean
    timestamps()

    belongs_to :user,           Helheim.User
    belongs_to :blog_post,      Helheim.BlogPost
    belongs_to :forum_topic,    Helheim.ForumTopic
    belongs_to :photo_album,    Helheim.PhotoAlbum
    belongs_to :photo,          Helheim.Photo
    belongs_to :profile,        Helheim.User
    belongs_to :calendar_event, Helheim.CalendarEvent
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :enabled])
    |> validate_required([:type])
    |> validate_inclusion(:type, @types)
  end

  def for_user(query, user) do
    from s in query,
    where: s.user_id == ^user.id
  end

  def for_type(query, type) do
    from s in query,
    where: s.type == ^type
  end

  def for_subject(query, %User{} = profile),                 do: from s in query, where: s.profile_id == ^profile.id
  def for_subject(query, %BlogPost{} = blog_post),           do: from s in query, where: s.blog_post_id == ^blog_post.id
  def for_subject(query, %ForumTopic{} = forum_topic),       do: from s in query, where: s.forum_topic_id == ^forum_topic.id
  def for_subject(query, %Photo{} = photo),                  do: from s in query, where: s.photo_id == ^photo.id
  def for_subject(query, %CalendarEvent{} = calendar_event), do: from s in query, where: s.calendar_event_id == ^calendar_event.id

  def enabled(query) do
    from s in query,
    where: s.enabled == true
  end

  def with_preloads(query) do
    query
    |> preload([:user, :profile, :blog_post, :forum_topic, :photo, :calendar_event])
  end

  def subject(subscription) do
    subscription.profile ||
    subscription.blog_post ||
    subscription.forum_topic ||
    subscription.photo ||
    subscription.calendar_event
  end

  def enable!(user, type, subject) do
    NotificationSubscription.changeset(existing_subscription(user, type, subject) || new_subscription(user, type, subject))
    |> Ecto.Changeset.put_change(:enabled, true)
    |> Repo.insert_or_update
  end

  def disable!(user, type, subject) do
    Ecto.Changeset.change(existing_subscription(user, type, subject) || new_subscription(user, type, subject))
    |> Ecto.Changeset.put_change(:enabled, false)
    |> Repo.insert_or_update
  end

  defp existing_subscription(user, type, subject) do
    NotificationSubscription
    |> NotificationSubscription.for_user(user)
    |> NotificationSubscription.for_type(type)
    |> NotificationSubscription.for_subject(subject)
    |> Repo.one
  end

  defp new_subscription(user, type, %User{} = profile),                 do: new_subscription(user, type) |> put_assoc(:profile, profile)
  defp new_subscription(user, type, %BlogPost{} = blog_post),           do: new_subscription(user, type) |> put_assoc(:blog_post, blog_post)
  defp new_subscription(user, type, %ForumTopic{} = forum_topic),       do: new_subscription(user, type) |> put_assoc(:forum_topic, forum_topic)
  defp new_subscription(user, type, %Photo{} = photo),                  do: new_subscription(user, type) |> put_assoc(:photo, photo)
  defp new_subscription(user, type, %CalendarEvent{} = calendar_event), do: new_subscription(user, type) |> put_assoc(:calendar_event, calendar_event)
  defp new_subscription(user, type) do
    NotificationSubscription.changeset(%NotificationSubscription{}, %{type: type})
    |> Ecto.Changeset.put_assoc(:user, user)
  end
end
