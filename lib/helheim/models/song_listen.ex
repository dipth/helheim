defmodule Helheim.SongListen do
  use Helheim, :model

  alias Helheim.Song
  alias Helheim.User

  schema "song_listens" do
    belongs_to :user, User
    belongs_to :song, Song
    field :played_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  def newest(query) do
    from l in query, order_by: [desc: l.played_at]
  end

  def for_user(query, user) do
    from l in query, where: l.user_id == ^user.id
  end

  def for_song(query, song) do
    from l in query, where: l.song_id == ^song.id
  end

  @doc """
  Collapses the listens to one per song, keeping the newest listen of each,
  so a song played on repeat only appears once in listing contexts.
  """
  def latest_per_song(query) do
    deduplicated =
      from l in query,
        distinct: l.song_id,
        order_by: [asc: l.song_id, desc: l.played_at]

    from l in subquery(deduplicated)
  end

  def not_from_users(query, nil), do: query
  def not_from_users(query, user_ids) do
    from l in query, where: l.user_id not in ^user_ids
  end

  def with_preloads(query) do
    from l in query, preload: [:user, :song]
  end
end
