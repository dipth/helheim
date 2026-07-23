defmodule HelheimWeb.SongView do
  use HelheimWeb, :view

  def detail_cover_url(song) do
    song.cover_image_url_large || song.cover_image_url
  end

  @doc """
  Renders an ISO 3166-1 alpha-2 country code as its flag emoji via the
  regional indicator codepoints - no image assets needed. MusicBrainz's
  user-assigned region codes (XW worldwide, XE Europe, ...) have no flag
  and render as letter boxes, so they are skipped - except XK (Kosovo),
  which platforms do render.
  """
  def country_flag(country_code) when is_binary(country_code) do
    case String.upcase(country_code) do
      <<a, b>> = upcased when a in ?A..?Z and b in ?A..?Z ->
        if a == ?X and upcased != "XK" do
          nil
        else
          upcased |> String.to_charlist() |> Enum.map(&(&1 + 127_397)) |> List.to_string()
        end
      _ ->
        nil
    end
  end
  def country_flag(_), do: nil

  @doc """
  A play/stop toggle for the song's 30 second preview, driven by
  assets/js/song_preview.js. Renders nothing when the song has no Deezer
  match. Defaults to the small overlay variant used on cover thumbnails;
  pass `:class` and `:label` for a regular labelled button.
  """
  def preview_button(conn, song, opts \\ [])
  def preview_button(_conn, %{deezer_id: nil}, _opts), do: nil
  def preview_button(conn, song, opts) do
    icon = content_tag(:i, "", class: "fa fa-fw fa-play")
    content = if opts[:label], do: [icon, " ", opts[:label]], else: icon

    content_tag(:button, content,
      type: "button",
      class: "song-preview-button #{Keyword.get(opts, :class, "song-preview-overlay")}",
      title: gettext("Play preview"),
      aria_label: gettext("Play preview"),
      data: [preview_url: song_preview_path(conn, :preview, song)]
    )
  end

  def listen_count_badge(count) do
    content_tag :span, class: "badge badge-default" do
      [content_tag(:i, "", class: "fa fa-fw fa-headphones"), {:safe, [" #{count}"]}]
    end
  end

  @doc """
  The hand-horns icon used for upvotes. Font Awesome's free set has no
  hand-horns glyph, so this is an inline SVG (Boxicons "hand rock", MIT),
  sized via `.icon-horns` to line up with the fixed-width font icons.
  """
  def horns_icon do
    {:safe,
     ~s(<svg class="icon-horns" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M19.5 5A2.5 2.5 0 0 0 17 7.5v.55c-.16-.03-.33-.05-.5-.05c-.56 0-1.08.2-1.5.51a2.47 2.47 0 0 0-2-.46V5.5a2.5 2.5 0 0 0-5 0v7.66l-1.61-1.05a2.39 2.39 0 0 0-3.69 1.88c-.04.68.22 1.34.7 1.82l3.73 3.73c.94.94 2.2 1.46 3.54 1.46h6.34c2.76 0 5-2.24 5-5V7.5a2.5 2.5 0 0 0-2.5-2.5ZM16 10.5c0-.28.22-.5.5-.5s.5.22.5.5v2c0 .28-.22.5-.5.5s-.5-.22-.5-.5zm-3 .5v-.5c0-.28.22-.5.5-.5s.5.22.5.5v3c0 .28-.22.5-.5.5s-.5-.22-.5-.5zm7 5c0 1.65-1.35 3-3 3h-6.34c-.79 0-1.56-.32-2.12-.88l-3.73-3.73a.35.35 0 0 1-.11-.3c0-.07.03-.19.15-.29a.39.39 0 0 1 .46-.02l3.16 2.05c.31.2.7.21 1.02.04s.52-.51.52-.88V5.5c0-.28.22-.5.5-.5s.5.22.5.5v8a2.5 2.5 0 0 0 2.5 2.5c.89 0 1.67-.47 2.11-1.17c.28.11.58.17.89.17a2.5 2.5 0 0 0 2.5-2.5v-5c0-.28.22-.5.5-.5s.5.22.5.5V16Z"/></svg>)}
  end

  @doc """
  The song's upvote count during a chart's window, as a plain badge. The
  interactive upvote toggle always shows the all-time total, so the two
  numbers can sit side by side on chart rows without disagreeing about
  what they mean.
  """
  def upvote_count_badge(count) do
    content_tag :span, class: "badge badge-default" do
      [content_tag(:i, "", class: "fa fa-fw fa-fire"), {:safe, [" #{count}"]}]
    end
  end

  @doc """
  A badge-styled toggle that upvotes the song - or removes the viewer's
  upvote if they already cast one - showing only the hand-horns icon and
  the song's all-time upvote count, matching the look of the comment and
  listen count badges. The button state comes from the required
  `upvoted_song_ids` assign (the ids the viewer has upvoted among the
  songs on the page - required so a page that forgets to compute it fails
  loudly instead of rendering every button un-upvoted). Voting happens
  asynchronously via assets/js/song_upvote.js, which snaps every badge
  for the song to the state and count the server returns.
  """
  def upvote_toggle(conn, song, assigns) do
    upvoted = song.id in Map.fetch!(assigns, :upvoted_song_ids)
    upvote_label = gettext("Upvote")
    remove_label = gettext("Remove your upvote")
    {badge, title} = if upvoted, do: {"badge-primary", remove_label}, else: {"badge-default", upvote_label}

    content_tag(:button, [horns_icon(), {:safe, " "}, content_tag(:span, "#{song.upvotes_count}", class: "song-upvote-count")],
      type: "button",
      class: "badge #{badge} song-upvote-button",
      title: title,
      aria_label: title,
      aria_pressed: "#{upvoted}",
      data: [
        song_id: song.id,
        upvoted: "#{upvoted}",
        upvote_url: song_upvote_path(conn, :upvote, song),
        title_upvote: upvote_label,
        title_remove: remove_label
      ])
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
