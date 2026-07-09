defmodule HelheimWeb.SongView do
  use HelheimWeb, :view

  def listen_count_badge(count) do
    content_tag :span, class: "badge badge-default" do
      [content_tag(:i, "", class: "fa fa-fw fa-headphones"), {:safe, [" #{count}"]}]
    end
  end

  def lastfm_link(nil, _label), do: nil
  def lastfm_link(url, label) do
    link to: url, target: "_blank", rel: "noopener" do
      [content_tag(:i, "", class: "fa fa-lastfm"), {:safe, " "}, label]
    end
  end

  def lastfm_artist_url(artist_name) do
    "https://www.last.fm/music/" <> URI.encode(artist_name, &URI.char_unreserved?/1)
  end

  def lastfm_album_url(artist_name, album_name) do
    lastfm_artist_url(artist_name) <> "/" <> URI.encode(album_name, &URI.char_unreserved?/1)
  end
end
