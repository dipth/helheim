defmodule Helheim.Spotify.Charts do
  @moduledoc """
  Aggregated listening statistics for the front page. Day and week
  boundaries are calculated in local Danish time (weeks start on Monday) and
  converted to UTC for querying.
  """

  import Ecto.Query
  alias Helheim.Repo
  alias Helheim.Song

  @timezone "Europe/Copenhagen"

  def top_songs_today(count), do: top_songs_since(start_of_day(), count)
  def top_songs_this_week(count), do: top_songs_since(start_of_week(), count)

  def top_songs_since(since, count) do
    Song
    |> Song.top_by_listens_since(since)
    |> limit(^count)
    |> Repo.all()
  end

  def start_of_day, do: Timex.now(@timezone) |> Timex.beginning_of_day() |> to_utc()
  def start_of_week, do: Timex.now(@timezone) |> Timex.beginning_of_week() |> to_utc()

  defp to_utc(datetime), do: Timex.Timezone.convert(datetime, "Etc/UTC")
end
