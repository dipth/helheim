defmodule HelheimWeb.MusicView do
  use HelheimWeb, :view

  # The music page leans on the song badges and Last.fm links. `only:` is
  # required - a bare import would also pull in SongView's render/2 and clash
  # with this view's own.
  import HelheimWeb.SongView,
    only: [country_flag: 1, listen_count_badge: 1, lastfm_link: 2, lastfm_artist_url: 1]

  @doc """
  A decade as a label, e.g. `1990` -> "1990s". Translated, since Danish forms it
  differently ("1990'erne").
  """
  def decade_label(decade), do: gettext("%{decade}s", decade: decade)

  @doc """
  The abbreviated label under a decade bar, e.g. `1990` -> "90s". The full label
  is on the bar's title attribute.
  """
  def decade_short_label(decade) do
    gettext("%{short}s", short: decade |> Integer.to_string() |> String.slice(-2, 2))
  end

  @doc """
  The biggest count in a chart, used as the 100% reference for its bars. Handles
  both the `{key, count}` rows and the `{name, count, artist}` artist rows, and
  cannot just read the head of the list: decades arrive in chronological order,
  not ordered by count.
  """
  def largest_count([]), do: 0
  def largest_count(rows), do: rows |> Enum.map(&row_count/1) |> Enum.max()

  @doc """
  A bar's size as a percentage of the biggest value in the same chart, floored
  at 2% so that the smallest entry is still a visible target.
  """
  def bar_percent(_count, largest) when largest in [nil, 0], do: 0
  def bar_percent(count, largest), do: max(round(count / largest * 100), 2)

  defp row_count({_key, count}), do: count
  defp row_count({_name, count, _artist}), do: count
end
