defmodule Helheim.TimeHelpers do
  def lt(timestamp, format) do
    {:ok, string} = timestamp
      |> Calendar.DateTime.shift_zone!("Europe/Copenhagen")
      |> Timex.lformat(format, "da")
    string
  end

  def time_ago_in_words(timestamp) do
    content = timestamp |> Timex.from_now("da")
    title = lt(timestamp, "{D}-{M}-{YYYY} {h24}:{m}")
    Phoenix.HTML.Tag.content_tag :span, content, title: title
  end
end
