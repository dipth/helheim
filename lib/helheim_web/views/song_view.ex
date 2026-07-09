defmodule HelheimWeb.SongView do
  use HelheimWeb, :view

  def duration(nil), do: nil
  def duration(duration_ms) do
    total_seconds = div(duration_ms, 1000)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading("#{seconds}", 2, "0")}"
  end

  def spotify_link(nil, _label), do: nil
  def spotify_link(url, label) do
    link to: url, target: "_blank", rel: "noopener" do
      [content_tag(:i, "", class: "fa fa-spotify"), {:safe, " "}, label]
    end
  end
end
