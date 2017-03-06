defmodule Helheim.TimeHelpers do
  def lt(timestamp, format) do
    {:ok, string} = timestamp
      |> Calendar.DateTime.shift_zone!("Europe/Copenhagen")
      |> Timex.lformat(format, "da", :strftime)
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
end
