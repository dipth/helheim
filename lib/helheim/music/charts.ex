defmodule Helheim.Music.Charts do
  @moduledoc """
  Aggregated listening statistics for the front page, based on rolling
  windows: the past 24 hours and the past 7 days.

  Listens from `excluded_user_ids` (the viewer's ignore list) are left out
  of the charts. The unfiltered charts are cached for a short interval since
  they are recomputed on every front page render; personalized results for
  viewers who actually ignore someone are computed directly.
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
    query = fn ->
      Song
      |> Song.top_by_listens_since(since, excluded_user_ids)
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

  def hours_ago(hours) do
    DateTime.add(DateTime.utc_now(), -hours * 3600, :second)
  end

  defp cache_ttl, do: Application.get_env(:helheim, :chart_cache_ttl_ms, 60_000)
end
