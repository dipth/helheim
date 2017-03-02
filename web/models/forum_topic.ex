defmodule Helheim.ForumTopic do
  use Helheim.Web, :model
  use Helheim.TimeLimitedEditableConcern

  schema "forum_topics" do
    field      :title,               :string
    field      :body,                :string
    field      :pinned,              :boolean
    field      :forum_replies_count, :integer
    field      :deleted_at,          Calecto.DateTimeUTC

    timestamps()

    belongs_to :forum,         Helheim.Forum
    belongs_to :user,          Helheim.User
    has_many   :forum_replies, Helheim.ForumReply
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body])
    |> trim_fields([:title, :body])
    |> validate_required([:title, :body])
    |> prepare_changes(fn changeset ->
      assoc(changeset.data, :forum)
      |> changeset.repo.update_all(inc: [forum_topics_count: 1])
      changeset
    end)
  end

  def latest_over_forum(per \\ 1) do
    from outer in __MODULE__,
      join: inner in fragment("""
        SELECT *, row_number() OVER (
          PARTITION BY forum_id
          ORDER BY inserted_at DESC
        ) FROM forum_topics
      """),
      where: inner.row_number <= ^per and inner.id == outer.id
  end

  def with_latest_reply(query) do
    forum_replies_query = Helheim.ForumReply.latest_over_forum_topic(1)
                          |> preload(:user)
    from ft in query,
      preload: [forum_replies: ^forum_replies_query]
  end
end
