defmodule Helheim.Forum do
  use Helheim, :model

  schema "forums" do
    field      :title,              :string
    field      :description,        :string
    field      :rank,               :integer
    field      :forum_topics_count, :integer
    field      :locked,             :boolean

    timestamps(type: :utc_datetime_usec)

    belongs_to :forum_category, Helheim.ForumCategory
    has_many   :forum_topics,   Helheim.ForumTopic
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :locked])
    |> trim_fields([:title, :description])
    |> validate_required([:title])
  end

  def in_positional_order(query) do
    from f in query,
    order_by: f.rank
  end

  def locked_for?(forum, user) do
    if Helheim.User.admin?(user) do
      false
    else
      forum.locked
    end
  end
end
