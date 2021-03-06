defmodule Helheim.Comment do
  use Helheim, :model

  use Helheim.TimeLimitedEditableConcern
  alias Helheim.Comment
  alias Helheim.User

  schema "comments" do
    field      :body,            :string
    field      :approved_at,     :utc_datetime_usec
    field      :deleted_at,      :utc_datetime_usec
    field      :deletion_reason, :string
    field      :notice,          :boolean
    belongs_to :author,          Helheim.User
    belongs_to :profile,         Helheim.User
    belongs_to :blog_post,       Helheim.BlogPost
    belongs_to :photo_album,     Helheim.PhotoAlbum
    belongs_to :photo,           Helheim.Photo
    belongs_to :deleter,         Helheim.User
    belongs_to :calendar_event,  Helheim.CalendarEvent

    timestamps(type: :utc_datetime_usec)
  end

  def newest(query) do
    from c in query,
    order_by: [desc: c.inserted_at]
  end

  def not_deleted(query) do
    from c in query, where: is_nil(c.deleted_at)
  end

  def with_preloads(query) do
    query
    |> preload([:author, :profile, :blog_post, :photo_album, [photo: :photo_album], :deleter, :calendar_event])
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, mod \\ false) do
    allowed_fields = if mod, do: [:body, :notice], else: [:body]
    struct
    |> cast(params, allowed_fields)
    |> trim_fields(:body)
    |> validate_required([:body])
  end

  def delete_changeset(struct, user, params \\ %{}) do
    struct
    |> cast(params, [:deletion_reason])
    |> trim_fields(:deletion_reason)
    |> put_assoc(:deleter, user)
    |> put_deleted_at()
  end

  def commentable(comment) do
    comment.profile ||
    comment.blog_post ||
    comment.photo_album ||
    comment.photo ||
    comment.calendar_event
  end

  def deletable_by?(_, %User{role: "admin"}), do: true
  def deletable_by?(_, %User{role: "mod"}), do: true
  def deletable_by?(%Comment{profile_id: profile_id}, user) when is_integer(profile_id), do: profile_id == user.id
  def deletable_by?(%Comment{blog_post_id: blog_post_id} = comment, user) when is_integer(blog_post_id), do: comment.blog_post.user_id == user.id
  def deletable_by?(%Comment{photo_id: photo_id} = comment, user) when is_integer(photo_id), do: comment.photo.photo_album.user_id == user.id
  def deletable_by?(_, _), do: false

  defp put_deleted_at(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        put_change(changeset, :deleted_at, DateTime.utc_now)
      _ ->
        changeset
    end
  end
end
