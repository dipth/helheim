defmodule Helheim.Notification do
  use Helheim, :model

  alias Helheim.Notification
  alias Helheim.Repo

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "notifications" do
    field :type,       :string
    field :seen_at,    :utc_datetime_usec
    field :clicked_at, :utc_datetime_usec
    field :duplicate_count, :integer, virtual: true

    timestamps(type: :utc_datetime_usec)

    belongs_to :recipient,      Helheim.User
    belongs_to :trigger_person, Helheim.User
    belongs_to :profile,        Helheim.User
    belongs_to :blog_post,      Helheim.BlogPost
    belongs_to :photo_album,    Helheim.PhotoAlbum
    belongs_to :photo,          Helheim.Photo
    belongs_to :forum_topic,    Helheim.ForumTopic
    belongs_to :calendar_event, Helheim.CalendarEvent
  end

  def newest(query) do
    from n in query,
    order_by: [desc: n.inserted_at]
  end

  def not_clicked(query) do
    from n in query,
    where: is_nil(n.clicked_at)
  end

  def with_preloads(query) do
    query
    |> preload([:trigger_person, :profile, :blog_post, :photo_album, :photo, :forum_topic, :calendar_event])
  end

  def list_not_clicked(recipient) do
    Ecto.assoc(recipient, :notifications)
    |> grouped_by_subject()
    |> not_clicked()
    |> Repo.all()
    |> Enum.map(fn(n) -> struct(Notification, Map.merge(n, %{
      id: List.first(n.ids),
      trigger_person_id: List.first(n.trigger_person_ids),
      duplicate_count: length(n.trigger_person_ids)
    })) end)
    |> Repo.preload([:trigger_person, :profile, :blog_post, :photo_album, :photo, :forum_topic, :calendar_event])
  end

  def query_duplicate_notifications(notification) do
    Notification
    |> Notification.not_clicked()
    |> where_subject_is_the_same(notification)
  end

  def subject(notification) do
    notification.profile ||
    notification.blog_post ||
    notification.photo_album ||
    notification.photo ||
    notification.forum_topic ||
    notification.calendar_event
  end

  ### PRIVATE

  defp grouped_by_subject(query) do
    from n in query,
    group_by: [
      n.recipient_id, n.type, n.profile_id, n.blog_post_id, n.photo_album_id,
      n.photo_id, n.forum_topic_id, n.calendar_event_id
    ],
    select: %{
      ids:                fragment("array_agg(?::text)", n.id),
      type:               n.type,
      seen_at:            max(n.seen_at),
      clicked_at:         max(n.clicked_at),
      inserted_at:        max(n.inserted_at),
      updated_at:         max(n.updated_at),
      recipient_id:       n.recipient_id,
      trigger_person_ids: fragment("array_agg(?)", n.trigger_person_id),
      profile_id:         n.profile_id,
      blog_post_id:       n.blog_post_id,
      photo_album_id:     n.photo_album_id,
      photo_id:           n.photo_id,
      forum_topic_id:     n.forum_topic_id,
      calendar_event_id:  n.calendar_event_id
    },
    order_by: [desc: max(n.inserted_at)]
  end

  defp where_subject_is_the_same(query, notification) do
    query
    |> where_subject_is_the_same(notification, :recipient_id)
    |> where_subject_is_the_same(notification, :type)
    |> where_subject_is_the_same(notification, :profile_id)
    |> where_subject_is_the_same(notification, :blog_post_id)
    |> where_subject_is_the_same(notification, :photo_album_id)
    |> where_subject_is_the_same(notification, :photo_id)
    |> where_subject_is_the_same(notification, :forum_topic_id)
    |> where_subject_is_the_same(notification, :calendar_event_id)
  end

  defp where_subject_is_the_same(query, notification, subject_field) do
    {:ok, value} = Map.fetch(notification, subject_field)
    case value do
      nil -> from(n in query, where: is_nil(field(n, ^subject_field)))
      _ -> from(n in query, where: field(n, ^subject_field) == ^value)
    end
  end
end
