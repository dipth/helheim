defmodule Helheim.Music.Stats do
  @moduledoc """
  All time, site wide music aggregates for the music page: the top genres, the
  top artists, listens per decade, and the totals behind the stat tiles.

  Unlike `Helheim.Music.Charts` these have no time window, so they sum the
  denormalized `songs.listens_count` instead of counting `song_listens` rows.
  That counter is kept exact by `Helheim.Lastfm.SyncService` and
  `Helheim.LastfmAccountService`, and it is the same counter the genre, decade
  and artist listings order by, so the music page and the pages it links to
  cannot disagree. Counting rows would mean reading the whole `song_listens`
  table on every recompute.

  Also unlike the charts, these are not personalized by the viewer's ignore
  list. A genre bar, a decade bar and an artist name attribute no content to
  any user, so there is nothing of an ignored user's to hide - which in turn
  means every result here is cacheable for every viewer.

  Nothing here is dropped when a vote is cast, and it deliberately stays out of
  `Helheim.Music.Charts.invalidate_cache/0`: no `Song` struct is embedded in
  these results, so no upvote badge is rendered from them, and the upvote tile
  is a site wide total that nobody can tell is a few minutes stale.
  """

  import Ecto.Query
  alias Helheim.Artist
  alias Helheim.Cache
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.Tag

  def top_genres(count) do
    Cache.fetch({:music_top_genres, count}, cache_ttl(), fn ->
      Tag
      |> Tag.top_by_listens()
      |> limit(^count)
      |> Repo.all()
    end)
  end

  def top_artists(count) do
    Cache.fetch({:music_top_artists, count}, cache_ttl(), fn ->
      Song
      |> Song.top_artists_by_listens()
      |> limit(^count)
      |> Repo.all()
      |> Artist.with_records()
    end)
  end

  def listens_per_decade do
    Cache.fetch({:music_listens_per_decade, :all}, cache_ttl(), fn ->
      Song
      |> Song.listens_per_decade()
      |> Repo.all()
    end)
  end

  @doc """
  The numbers behind the stat tiles: how many songs, artists, listens, upvotes
  and listeners the site has.

  Artists are counted as distinct `lower(artist_name)` across songs rather than
  as rows in `artists`, so the tile agrees with `top_artists/1`; the artists
  table only holds the names enrichment has already reached.
  """
  def totals do
    Cache.fetch({:music_totals, :all}, cache_ttl(), &compute_totals/0)
  end

  defp compute_totals do
    # sum/1 over zero rows is NULL, and an empty database is the realistic
    # first case, so every sum is coalesced to a number the tiles can render.
    song_totals =
      Repo.one(
        from s in Song,
          select: %{
            songs: count(s.id),
            listens: coalesce(sum(s.listens_count), 0),
            upvotes: coalesce(sum(s.upvotes_count), 0),
            artists: fragment("count(distinct lower(?))", s.artist_name)
          }
      )

    listeners = Repo.one(from l in SongListen, select: count(l.user_id, :distinct))

    Map.put(song_totals, :listeners, listeners)
  end

  defp cache_ttl, do: Application.get_env(:helheim, :music_stats_cache_ttl_ms, :timer.minutes(5))
end
