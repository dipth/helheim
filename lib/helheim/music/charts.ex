defmodule Helheim.Music.Charts do
  @moduledoc """
  Aggregated listening and upvote statistics for the front page, based on
  rolling windows: the past 24 hours and the past 7 days.

  Listens and upvotes from `excluded_user_ids` (the viewer's ignore list)
  are left out of the charts. The unfiltered charts are cached for a short
  interval since they are recomputed on every front page render;
  personalized results for viewers who actually ignore someone are computed
  directly.
  """

  import Ecto.Query
  alias Helheim.Cache
  alias Helheim.Repo
  alias Helheim.Song

  def top_songs_last_day(count, excluded_user_ids \\ nil) do
    top_songs_since(hours_ago(24), count, excluded_user_ids, cache_key: {:top_songs_last_day, count})
  end

  def top_songs_last_week(count, excluded_user_ids \\ nil) do
    top_songs_since(hours_ago(24 * 7), count, excluded_user_ids, cache_key: {:top_songs_last_week, count})
  end

  def top_songs_since(since, count, excluded_user_ids \\ nil, opts \\ []) do
    top_songs(&Song.top_by_listens_since/3, since, count, excluded_user_ids, opts)
  end

  def top_upvoted_songs_last_day(count, excluded_user_ids \\ nil) do
    top_upvoted_songs_since(hours_ago(24), count, excluded_user_ids, cache_key: {:top_upvoted_songs_last_day, count})
  end

  def top_upvoted_songs_last_week(count, excluded_user_ids \\ nil) do
    top_upvoted_songs_since(hours_ago(24 * 7), count, excluded_user_ids, cache_key: {:top_upvoted_songs_last_week, count})
  end

  def top_upvoted_songs_since(since, count, excluded_user_ids \\ nil, opts \\ []) do
    top_songs(&Song.top_by_upvotes_since/3, since, count, excluded_user_ids, opts)
  end

  defp top_songs(chart_fun, since, count, excluded_user_ids, opts) do
    query = fn ->
      Song
      |> chart_fun.(since, excluded_user_ids)
      |> limit(^count)
      |> Repo.all()
    end

    cache_key = Keyword.get(opts, :cache_key)

    if cache_key && excluded_user_ids in [nil, []] do
      Cache.fetch(cache_key, cache_ttl(), query)
    else
      query.()
    end
  end

  @doc """
  Drops every cached chart on this node so the next render recomputes.

  Called when a vote is cast or removed: the upvote charts genuinely
  reorder, and the listen charts are included too because their cached
  rows embed `Song` structs whose `upvotes_count` the upvote badges
  display. This deliberately trades cache efficiency for freshness - under
  heavy vote traffic the recompute rate scales with the vote rate instead
  of being capped by the ttl. If chart queries ever show up in monitoring,
  the listen charts can be dropped from this list at the cost of vote
  counts inside them lagging up to one ttl.
  """
  def invalidate_cache do
    Enum.each(
      [:top_songs_last_day, :top_songs_last_week, :top_upvoted_songs_last_day, :top_upvoted_songs_last_week],
      &Cache.invalidate/1
    )
  end

  def hours_ago(hours) do
    DateTime.add(DateTime.utc_now(), -hours * 3600, :second)
  end

  defp cache_ttl, do: Application.get_env(:helheim, :chart_cache_ttl_ms, 60_000)
end
