defmodule Helheim.Repo.Migrations.AddMusicGenreIndex do
  use Ecto.Migration

  def change do
    # Serves both the top genre aggregate, which walks every position 1 tag, and
    # the genre pages, which look up one tag's songs. The existing
    # songs_tags(tag_id) index matches a song's other tags too and does not
    # carry position, so it needs a heap fetch per row just to discard four rows
    # in five; leading with tag_id and including song_id answers both queries
    # from the index alone.
    create index(:songs_tags, [:tag_id, :song_id], where: "position = 1", name: :songs_tags_genre_index)
  end
end
