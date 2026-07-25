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

  # Metadata sources occasionally hand back a nonsense release year; the decade
  # breakdown clamps to years that could plausibly be a recording so a single
  # bad row cannot add an "0s" or "3020s" column to the chart.
  @earliest_release_year 1900
  @latest_release_year 2100

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

  @doc """
  Artist names ordered by total listens, all time and site wide, as
  `{artist_name, listen_count}`.

  Grouped by `lower(artist_name)`, not `artist_name`: the songs unique index is
  on `(lower(artist_name), lower(title))`, so two songs by the same artist can
  legitimately be stored with different casing and a raw group_by would split
  the artist in two. `min(artist_name)` then picks one spelling
  deterministically.
  """
  def top_artists_by_listens(query) do
    from s in query,
      where: s.listens_count > 0,
      group_by: fragment("lower(?)", s.artist_name),
      order_by: [desc: sum(s.listens_count), asc: fragment("lower(?)", s.artist_name)],
      select: {min(s.artist_name), sum(s.listens_count)}
  end

  @doc """
  Listens grouped by the decade a song was released in, as
  `{decade, listen_count}` ascending by decade. Songs with no release year -
  not enriched yet, or the metadata sources had no year - are left out
  entirely rather than bucketed as unknown.
  """
  def listens_per_decade(query) do
    from s in query,
      where: s.release_year >= ^@earliest_release_year and s.release_year <= ^@latest_release_year,
      where: s.listens_count > 0,
      group_by: selected_as(:decade),
      order_by: [asc: selected_as(:decade)],
      select: {selected_as(fragment("(? / 10) * 10", s.release_year), :decade), sum(s.listens_count)}
  end

  @doc """
  Songs whose genre - the tag at `position: 1` - is the tag with the given id.
  """
  def for_genre(query, tag_id) do
    from s in query,
      join: st in Helheim.SongTag, on: st.song_id == s.id,
      where: st.tag_id == ^tag_id and st.position == 1
  end

  @doc """
  Songs released in the ten years starting at `decade`, so 1980 covers 1980
  through 1989. A song with no release year fails the comparison and is left
  out without needing an explicit check.
  """
  def for_decade(query, decade) when is_integer(decade) do
    from s in query, where: s.release_year >= ^decade and s.release_year < ^(decade + 10)
  end

  @doc """
  Songs by the given artist, matched case-insensitively on `artist_name` - the
  same identity rule the artists table uses, and `artist_id` is no substitute
  since it stays nil until enrichment runs. Uses the leading column of the
  `songs_artist_title_index`.
  """
  def for_artist_name(query, artist_name) do
    from s in query, where: fragment("lower(?)", s.artist_name) == ^String.downcase(artist_name)
  end

  def most_listened(query) do
    from s in query, order_by: [desc: s.listens_count, asc: s.id]
  end
end
