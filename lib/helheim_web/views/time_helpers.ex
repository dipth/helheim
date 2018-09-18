defmodule HelheimWeb.TimeHelpers do
  import HelheimWeb.Gettext

  def lt(nil, _), do: nil
  def lt(timestamp, format) do
    {:ok, string} = timestamp
      |> Calendar.DateTime.shift_zone!("Europe/Copenhagen")
      |> Timex.lformat(format, "da", :strftime)
    string
  end

  def lt(timestamp, :long, :no_shift) do
    {:ok, string} = Timex.lformat(timestamp, "%A d. %d. %B %Y, kl. %H:%M", "da", :strftime)
    string
  end

  def time_ago_in_words(timestamp, opts \\ []) do
    content = timestamp |> Timex.from_now("da")
    if opts[:simple] == true do
      content
    else
      title = lt(timestamp, "%d. %b %Y kl. %H:%M")
      Phoenix.HTML.Tag.content_tag :span, content, title: title
    end
  end

  @doc """
  Generates month date_select/datetime_select options wrapped in a gettext call.
  """
  def gettext_month_options do
    [
      {gettext("January"), 1},
      {gettext("February"), 2},
      {gettext("March"), 3},
      {gettext("April"), 4},
      {gettext("May"), 5},
      {gettext("June"), 6},
      {gettext("July"), 7},
      {gettext("August"), 8},
      {gettext("September"), 9},
      {gettext("October"), 10},
      {gettext("November"), 11},
      {gettext("December"), 12},
    ]
  end
end
