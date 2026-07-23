defmodule Helheim.SongUpvote do
  use Helheim, :model

  schema "song_upvotes" do
    belongs_to :user, Helheim.User
    belongs_to :song, Helheim.Song
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct) do
    struct
    |> change()
    |> unique_constraint(:user_id, name: :song_upvotes_user_id_song_id_index)
  end

  def for_user(query, user) do
    from u in query, where: u.user_id == ^user.id
  end

  def for_song(query, song) do
    from u in query, where: u.song_id == ^song.id
  end
end
