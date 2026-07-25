defmodule Helheim.Tag do
  use Helheim, :model

  alias Helheim.Song
  alias Helheim.SongTag
  alias Helheim.Tag

  schema "tags" do
    field :name, :string
    has_many :song_tags, Helheim.SongTag
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> trim_fields(:name)
    |> validate_required([:name])
    |> validate_length(:name, max: 40)
    |> unique_constraint(:name, name: :tags_name_index)
  end

  @doc """
  Finds or creates the tag with the given name, matching case-insensitively.
  """
  def get_or_create_by_name!(name), do: Helheim.NamedLookup.get_or_create!(Tag, name)

  def get_by_name(name), do: Helheim.NamedLookup.get(Tag, name)

  @doc """
  Tags used as a genre - the tag at `position: 1` on a song, the one the song
  page labels "Genre" - ordered by how many listens the songs carrying them
  have, descending.

  Sums the denormalized `songs.listens_count` rather than counting listen
  rows: with no time window to narrow it down, counting rows would mean
  reading every listen on the site. Songs that have never been played are
  left out entirely, so a genre only appears once somebody has played it.
  """
  def top_by_listens(query) do
    from t in query,
      join: st in SongTag, on: st.tag_id == t.id,
      join: s in Song, on: s.id == st.song_id,
      where: st.position == 1 and s.listens_count > 0,
      group_by: t.id,
      order_by: [desc: sum(s.listens_count), asc: t.id],
      select: {t, sum(s.listens_count)}
  end
end
