defmodule Helheim.ForumCategory do
  use Helheim, :model

  schema "forum_categories" do
    field :title,       :string
    field :description, :string
    field :rank,        :integer

    timestamps()

    has_many :forums, Helheim.Forum
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description])
    |> trim_fields([:title, :description])
    |> validate_required([:title])
  end

  def in_positional_order(query) do
    from c in query,
    order_by: c.rank
  end

  def with_forums(query) do
    forums_query = Helheim.Forum |> Helheim.Forum.in_positional_order
    from fc in query,
      preload: [forums: ^forums_query]
  end

  def with_forums_and_latest_topic(query) do
    forum_topics_query = Helheim.ForumTopic.latest_over_forum(1) |> preload(:user)
    forums_query       = Helheim.Forum
                         |> Helheim.Forum.in_positional_order
                         |> preload(forum_topics: ^forum_topics_query)
    from fc in query,
      preload: [forums: ^forums_query]
  end
end
