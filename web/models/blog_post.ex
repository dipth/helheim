defmodule Helheim.BlogPost do
  use Helheim.Web, :model

  schema "blog_posts" do
    field :title,         :string
    field :body,          :string
    field :visitor_count, :integer
    field :comment_count, :integer
    field :published,     :boolean
    field :published_at,  Calecto.DateTimeUTC

    timestamps()

    belongs_to :user,                Helheim.User
    has_many   :comments,            Helheim.Comment
    has_many   :visitor_log_entries, Helheim.VisitorLogEntry
  end

  def newest(query) do
    from p in query,
    order_by: [desc: [p.published_at, p.inserted_at]]
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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body, :published])
    |> trim_fields(:title)
    |> validate_required([:title, :body])
    |> scrub_body()
    |> set_published_at()
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
