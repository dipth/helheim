defmodule HelheimWeb.SongView do
  use HelheimWeb, :view

  def detail_cover_url(song) do
    song.cover_image_url_large || song.cover_image_url
  end

  @doc """
  Renders an ISO 3166-1 alpha-2 country code as its flag emoji via the
  regional indicator codepoints - no image assets needed.
  """
  def country_flag(<<_, _>> = country_code) do
    country_code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 + 127_397))
    |> List.to_string()
  end
  def country_flag(_), do: nil

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
