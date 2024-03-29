defmodule Helheim.BlogPost do
  use Helheim, :model

  schema "blog_posts" do
    field :title,         :string
    field :body,          :string
    field :visitor_count, :integer
    field :comment_count, :integer
    field :published,     :boolean
    field :published_at,  :utc_datetime_usec
    field :visibility,    :string
    field :hide_comments, :boolean
    field :mod_message,   :string

    timestamps(type: :utc_datetime_usec)

    belongs_to :user,                Helheim.User
    has_many   :comments,            Helheim.Comment
    has_many   :visitor_log_entries, Helheim.VisitorLogEntry
  end

  def newest(query) do
    from p in query,
    order_by: [desc: p.published_at, desc: p.inserted_at]
  end

  @newest_for_frontpage_partition_query """
    (SELECT blog_posts.id, row_number() OVER (
      PARTITION BY blog_posts.user_id
      ORDER BY blog_posts.published_at DESC
    ) FROM blog_posts WHERE blog_posts.published = TRUE)
  """
  def newest_for_frontpage(current_user, limit, ignoree_ids \\ []) do
    from bp in (Helheim.BlogPost |> published |> visible_by(current_user) |> not_from_ignoree(ignoree_ids) |> not_private |> newest),
    join: partition in fragment(@newest_for_frontpage_partition_query),
    where: partition.row_number <= ^1 and partition.id == bp.id,
    limit: ^limit
  end

  def published(query) do
    from p in query,
    where: p.published == true
  end

  def published_by_owner(query, owner, current_user) do
    cond do
      owner.id == current_user.id -> query
      true -> query |> published
    end
  end

  def not_from_ignoree(query, ignoree_ids) do
    from p in query,
    where: p.user_id not in ^ignoree_ids
  end

  def visible_by(query, user) do
    verified = Helheim.User.verified?(user)

    from p in query,
    where: p.visibility == "public" or p.user_id == ^user.id or (p.visibility == "verified_only" and ^verified) or (
      (p.visibility == "friends_only" or p.visibility == "verified_only") and fragment(
        "EXISTS(?)",
        fragment(
          "
            SELECT 1 FROM friendships
            WHERE
              friendships.accepted_at IS NOT NULL AND
              friendships.sender_id IN (?,?) AND
              friendships.recipient_id IN (?,?)
          ", p.user_id, ^user.id, p.user_id, ^user.id
        )
      )
    )
  end

  def not_private(query) do
    from p in query,
    where: p.visibility != "private"
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body, :published, :visibility, :hide_comments])
    |> trim_fields(:title)
    |> validate_required([:title, :body, :visibility])
    |> validate_inclusion(:visibility, Helheim.Visibility.visibilities)
    |> scrub_body()
    |> set_published_at()
  end

  def edited?(%{published_at: nil}), do: false
  def edited?(blog_post) do
    Timex.diff(blog_post.updated_at, blog_post.published_at, :minutes) > 0
  end

  defp scrub_body(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{body: body}} ->
        put_change(changeset, :body, body |> HtmlSanitizeEx.Scrubber.scrub(Helheim.Scrubber))
      _ ->
        changeset
    end
  end

  defp set_published_at(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{published: true}} ->
        unless get_field(changeset, :published_at) do
          put_change(changeset, :published_at, DateTime.utc_now)
        else
          changeset
        end
      _ ->
        changeset
    end
  end
end
