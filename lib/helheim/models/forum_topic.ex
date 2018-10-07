defmodule Helheim.ForumTopic do
  use Helheim, :model

  use Helheim.TimeLimitedEditableConcern

  schema "forum_topics" do
    field      :title,               :string
    field      :body,                :string
    field      :pinned,              :boolean
    field      :forum_replies_count, :integer
    field      :deleted_at,          Calecto.DateTimeUTC
    field      :locked_at,           Calecto.DateTimeUTC

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

  def newest_for_frontpage(limit) do
    sq = from(
      ft in Helheim.ForumTopic,
      left_join: fr in Helheim.ForumReply, on: fr.forum_topic_id == ft.id,
      group_by:  ft.id,
      select:    %{id: ft.id, last_updated_at: fragment("coalesce(?, ?)", max(fr.updated_at), ft.updated_at)},
      order_by:  [desc: fragment("coalesce(?, ?)", max(fr.updated_at), ft.updated_at)],
      limit:     ^limit
    )
    from(
      ft in      Helheim.ForumTopic,
      join:     sub_ft in subquery(sq), on: ft.id == sub_ft.id,
      order_by: [desc: sub_ft.last_updated_at],
      preload:  [:forum, :user]
    )
  end

  def in_order(query) do
    from ft in query,
      order_by: [desc: :pinned, desc: :updated_at]
  end

  def newest(query) do
    from ft in query,
      order_by: [desc: :inserted_at]
  end

  def locked?(forum_topic) do
    forum_topic.locked_at != nil
  end
end
