defmodule Helheim.Song do
  use Helheim, :model

  alias Helheim.SongListen

  schema "songs" do
    field :title,                 :string
    field :artist_name,           :string
    field :album_name,            :string
    field :cover_image_url,       :string
    field :cover_image_url_small, :string
    field :lastfm_track_url,      :string
    field :comment_count,         :integer
    field :listens_count,         :integer
    has_many :listens, SongListen
    has_many :comments, Helheim.Comment
    timestamps(type: :utc_datetime_usec)
  end

  @metadata_fields [:album_name, :cover_image_url, :cover_image_url_small, :lastfm_track_url]

  def metadata_fields, do: @metadata_fields

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :artist_name | @metadata_fields])
    |> validate_required([:title, :artist_name])
    |> unique_constraint(:title, name: :songs_artist_title_index)
  end

  def top_by_listens_since(query, since) do
    from s in query,
      join: l in SongListen, on: l.song_id == s.id,
      where: l.played_at >= ^since,
      group_by: s.id,
      order_by: [desc: count(l.id), asc: s.id],
      select: {s, count(l.id)}
  end

  def top_for_user(query, user) do
    from s in query,
      join: l in SongListen, on: l.song_id == s.id,
      where: l.user_id == ^user.id,
      group_by: s.id,
      order_by: [desc: count(l.id), asc: s.id],
      select: {s, count(l.id)}
  end

  def top_artists_for_user(query, user) do
    from s in query,
      join: l in SongListen, on: l.song_id == s.id,
      where: l.user_id == ^user.id,
      group_by: s.artist_name,
      order_by: [desc: count(l.id), asc: s.artist_name],
      select: {s.artist_name, count(l.id)}
  end
end
