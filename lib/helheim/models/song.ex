defmodule Helheim.Song do
  use Helheim, :model

  alias Helheim.SongListen

  schema "songs" do
    field :spotify_track_id,      :string
    field :title,                 :string
    field :artist_name,           :string
    field :artist_spotify_id,     :string
    field :album_name,            :string
    field :album_spotify_id,      :string
    field :cover_image_url,       :string
    field :cover_image_url_small, :string
    field :spotify_track_url,     :string
    field :spotify_artist_url,    :string
    field :spotify_album_url,     :string
    field :duration_ms,           :integer
    field :preview_url,           :string
    field :comment_count,         :integer
    field :listens_count,         :integer
    has_many :listens, SongListen
    has_many :comments, Helheim.Comment
    timestamps(type: :utc_datetime_usec)
  end

  @metadata_fields [
    :title, :artist_name, :artist_spotify_id, :album_name, :album_spotify_id,
    :cover_image_url, :cover_image_url_small, :spotify_track_url,
    :spotify_artist_url, :spotify_album_url, :duration_ms, :preview_url
  ]

  def metadata_fields, do: @metadata_fields

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:spotify_track_id | @metadata_fields])
    |> validate_required([:spotify_track_id, :title, :artist_name])
    |> unique_constraint(:spotify_track_id)
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
      group_by: [s.artist_name, s.spotify_artist_url],
      order_by: [desc: count(l.id), asc: s.artist_name],
      select: {s.artist_name, s.spotify_artist_url, count(l.id)}
  end
end
