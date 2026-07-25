defmodule HelheimWeb.MusicHelpers do
  @moduledoc """
  Links into, and labels for, the music pages.

  Artist pages are keyed by name, not by id, so the route is a glob. Splitting
  the name on "/" turns AC/DC into two real path segments, which
  `HelheimWeb.MusicController` rejoins - and Phoenix glob helpers take a list
  of segments, so handing them a bare name would raise rather than build a
  path. Wrapped here so no template has to remember either detail.
  """
  import HelheimWeb.Router.Helpers

  def artist_page_path(conn, artist_name) do
    music_path(conn, :artist, String.split(artist_name, "/"))
  end

  @doc """
  A tag name as a display label. Tags come from Last.fm in whatever casing the
  people tagging used - almost always all lower case - so the first letter of
  each word is upper cased for display. A song's genre is just its first tag, so
  this covers every genre label too.

  Only the leading letter of each word is touched and the rest is left exactly as
  stored, which keeps an acronym someone typed properly ("NWOBHM") intact where
  capitalizing whole words would flatten it to "Nwobhm". A word starts after
  anything that is not a letter or a digit, so hyphens and ampersands split too
  ("post-punk" -> "Post-Punk", "r&b" -> "R&B"), while a digit does not
  ("80s" stays "80s").
  """
  def tag_label(nil), do: nil
  def tag_label(name) do
    String.replace(name, ~r/(?<![\p{L}\p{N}])\p{Ll}/u, &String.upcase/1)
  end
end
