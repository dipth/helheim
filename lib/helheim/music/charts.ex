defmodule Helheim.Music.Charts do
  @moduledoc """
  Aggregated listening statistics for the front page. Day and week
  boundaries are calculated in local Danish time (weeks start on Monday) and
  converted to UTC for querying.

  Listens from `excluded_user_ids` (the viewer's ignore list) are left out
  of the charts. The unfiltered charts are cached for a short interval since
  they are recomputed on every front page render; personalized results for
  viewers who actually ignore someone are computed directly.
  """

  import Ecto.Query
  alias Helheim.Cache
  alias Helheim.Repo
  alias Helheim.Song

  @timezone "Europe/Copenhagen"

  def top_songs_today(count, excluded_user_ids \\ nil) do
    top_songs_since(start_of_day(), count, excluded_user_ids, cache_key: {:top_songs_today, count})
  end

  def top_songs_this_week(count, excluded_user_ids \\ nil) do
    top_songs_since(start_of_week(), count, excluded_user_ids, cache_key: {:top_songs_this_week, count})
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

  def start_of_day, do: Timex.now(@timezone) |> Timex.beginning_of_day() |> to_utc()
  def start_of_week, do: Timex.now(@timezone) |> Timex.beginning_of_week() |> to_utc()

  defp to_utc(datetime), do: Timex.Timezone.convert(datetime, "Etc/UTC")

  defp cache_ttl, do: Application.get_env(:helheim, :chart_cache_ttl_ms, 60_000)
end
