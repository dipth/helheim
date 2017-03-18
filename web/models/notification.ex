defmodule Helheim.Notification do
  use Helheim.Web, :model

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "notifications" do
    field :type,       :string
    field :seen_at,    Calecto.DateTimeUTC
    field :clicked_at, Calecto.DateTimeUTC

    timestamps()

    belongs_to :recipient,      Helheim.User
    belongs_to :trigger_person, Helheim.User
    belongs_to :profile,        Helheim.User
    belongs_to :blog_post,      Helheim.BlogPost
    belongs_to :photo_album,    Helheim.PhotoAlbum
    belongs_to :photo,          Helheim.Photo
    belongs_to :forum_topic,    Helheim.ForumTopic
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
    |> preload([:trigger_person, :profile, :blog_post, :photo_album, :photo, :forum_topic])
  end

  def subject(notification) do
    notification.profile ||
    notification.blog_post ||
    notification.photo_album ||
    notification.photo ||
    notification.forum_topic
  end
end
