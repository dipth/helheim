defmodule Helheim.Song do
  use Helheim, :model

  alias Helheim.SongListen

  schema "songs" do
    field :title,                 :string
    field :artist_name,           :string
    field :album_name,            :string
    field :cover_image_url,       :string
    field :cover_image_url_small, :string
    field :cover_image_url_large, :string
    field :lastfm_track_url,      :string
    field :mbid,                  :string
    field :artist_mbid,           :string
    field :album_mbid,            :string
    field :release_year,          :integer
    field :duration_seconds,      :integer
    field :deezer_id,             :integer
    field :enriched_at,           :utc_datetime_usec
    field :comment_count,         :integer
    field :listens_count,         :integer
    field :upvotes_count,         :integer
    belongs_to :artist, Helheim.Artist
    has_many :listens, SongListen
    has_many :comments, Helheim.Comment
    has_many :upvotes, Helheim.SongUpvote
    has_many :song_tags, Helheim.SongTag
    has_many :tags, through: [:song_tags, :tag]
    timestamps(type: :utc_datetime_usec)
  end

  @metadata_fields [:album_name, :cover_image_url, :cover_image_url_small, :lastfm_track_url, :mbid, :artist_mbid, :album_mbid]
  @enrichment_fields [:cover_image_url_large, :release_year, :duration_seconds, :deezer_id, :enriched_at]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :artist_name | @metadata_fields ++ @enrichment_fields])
    |> validate_required([:title, :artist_name])
    |> unique_constraint(:title, name: :songs_artist_title_index)
  end

  def unenriched(query) do
    from s in query, where: is_nil(s.enriched_at)
  end

  def top_by_listens_since(query, since, excluded_user_ids \\ nil)
  def top_by_listens_since(query, since, excluded_user_ids) when excluded_user_ids in [nil, []] do
    from s in query,
      join: l in SongListen, on: l.song_id == s.id,
      where: l.played_at >= ^since,
      group_by: s.id,
      order_by: [desc: count(l.id), asc: s.id],
      select: {s, count(l.id)}
  end
  def top_by_listens_since(query, since, excluded_user_ids) do
    from [s, l] in top_by_listens_since(query, since),
      where: l.user_id not in ^excluded_user_ids
  end

  def top_by_upvotes_since(query, since, excluded_user_ids \\ nil)
  def top_by_upvotes_since(query, since, excluded_user_ids) when excluded_user_ids in [nil, []] do
    from s in query,
      join: u in Helheim.SongUpvote, on: u.song_id == s.id,
      where: u.inserted_at >= ^since,
      group_by: s.id,
      order_by: [desc: count(u.id), asc: s.id],
      select: {s, count(u.id)}
  end
  def top_by_upvotes_since(query, since, excluded_user_ids) do
    from [s, u] in top_by_upvotes_since(query, since),
      where: u.user_id not in ^excluded_user_ids
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
