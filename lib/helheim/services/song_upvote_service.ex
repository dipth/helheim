defmodule Helheim.SongUpvoteService do
  @moduledoc """
  Toggling a user's upvote on a song, keeping the cached `upvotes_count` on
  the song in sync. A user can upvote a song at most once - enforced by a
  unique index on `(user_id, song_id)` - so a duplicate upvote fails with
  `{:error, :song_upvote, changeset, _}` and leaves the count untouched,
  and removing an upvote that is not there is a no-op.

  Successful toggles invalidate the cached song charts (see
  `Helheim.Music.Charts.invalidate_cache/0`) so the next render on this
  node reflects the vote immediately.
  """

  import Ecto.Query
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Helheim.Music.Charts
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.SongUpvote

  def upvote!(song, user) do
    Multi.new
    |> Multi.insert(:song_upvote, build_upvote(song, user))
    |> Multi.update_all(:upvotes_count, (Song |> where(id: ^song.id)), inc: [upvotes_count: 1])
    |> Repo.transaction
    |> invalidate_charts()
  end

  def remove_upvote!(song, user) do
    Multi.new
    |> Multi.delete_all(:song_upvote, (SongUpvote |> SongUpvote.for_user(user) |> SongUpvote.for_song(song)))
    |> dec_upvotes_count(song)
    |> Repo.transaction
    |> invalidate_charts()
  end

  @doc """
  Deletes all of the user's upvotes and keeps the song upvote counters in
  sync. Used when the user account is deleted, before the FK cascade would
  otherwise remove the rows without touching the counters.
  """
  def delete_upvotes_for_user!(user) do
    upvotes_query = from u in SongUpvote, where: u.user_id == ^user.id

    counts_query =
      from u in subquery(upvotes_query),
        group_by: u.song_id,
        select: %{song_id: u.song_id, upvote_count: count(u.id)}

    dec_query =
      from s in Song,
        join: c in subquery(counts_query), on: c.song_id == s.id,
        update: [set: [upvotes_count: s.upvotes_count - c.upvote_count]]

    Multi.new()
    |> Multi.update_all(:dec_upvotes_counts, dec_query, [])
    |> Multi.delete_all(:delete_upvotes, upvotes_query)
    |> Repo.transaction()
    |> invalidate_charts()
  end

  @doc """
  Given a user and a collection of songs - as `Song` structs, song ids,
  `{song, count}` chart rows, or `SongListen`s, in any combination -
  returns the ids of those songs the user has upvoted. Lets a listing
  render the correct button state with a single query instead of one per
  song.
  """
  def upvoted_song_ids(nil, _items), do: []
  def upvoted_song_ids(user, items) do
    case items |> Enum.map(&song_id/1) |> Enum.uniq() do
      [] ->
        []
      song_ids ->
        SongUpvote
        |> SongUpvote.for_user(user)
        |> where([u], u.song_id in ^song_ids)
        |> select([u], u.song_id)
        |> Repo.all
    end
  end

  defp song_id(%Song{id: id}), do: id
  defp song_id(%SongListen{song_id: id}), do: id
  defp song_id({%Song{id: id}, _count}), do: id
  defp song_id(id) when is_integer(id), do: id

  defp build_upvote(song, user) do
    SongUpvote.changeset(%SongUpvote{})
    |> Changeset.put_assoc(:song, song)
    |> Changeset.put_assoc(:user, user)
  end

  # Only decrements by the number of upvotes actually deleted (0 or 1), so
  # removing a non-existent upvote does not push the count negative.
  defp dec_upvotes_count(multi, song) do
    Multi.run(multi, :upvotes_count, fn repo, %{song_upvote: {deleted, _}} ->
      if deleted > 0 do
        repo.update_all((Song |> where(id: ^song.id)), inc: [upvotes_count: -deleted])
      end

      {:ok, deleted}
    end)
  end

  defp invalidate_charts({:ok, _} = result) do
    Charts.invalidate_cache()
    result
  end
  defp invalidate_charts(result), do: result
end
