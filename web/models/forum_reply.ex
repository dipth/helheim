defmodule Helheim.ForumReply do
  use Helheim.Web, :model
  use Helheim.TimeLimitedEditableConcern

  schema "forum_replies" do
    field      :body,                :string
    field      :deleted_at,          Calecto.DateTimeUTC
    field      :notice,              :boolean

    timestamps()

    belongs_to :forum_topic, Helheim.ForumTopic
    belongs_to :user,        Helheim.User
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body])
    |> trim_fields([:body])
    |> validate_required([:body])
    |> prepare_changes(fn changeset ->
      assoc(changeset.data, :forum_topic)
      |> changeset.repo.update_all(inc: [forum_replies_count: 1], set: [updated_at: DateTime.utc_now])
      changeset
    end)
  end

  def latest_over_forum_topic(per \\ 1) do
    from outer in __MODULE__,
      join: inner in fragment("""
        SELECT *, row_number() OVER (
          PARTITION BY forum_topic_id
          ORDER BY inserted_at DESC
        ) FROM forum_replies
      """),
      where: inner.row_number <= ^per and inner.id == outer.id
  end

  def in_order(query) do
    from fr in query,
      order_by: [asc: :inserted_at]
  end

  def newest(query) do
    from fr in query,
      order_by: [desc: :inserted_at]
  end
end
