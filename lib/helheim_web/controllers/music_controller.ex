defmodule HelheimWeb.MusicController do
  use HelheimWeb, :controller
  alias Helheim.Artist
  alias Helheim.Song
  alias Helheim.SongUpvoteService
  alias Helheim.Tag
  alias Helheim.Music.Charts
  alias Helheim.Music.Stats

  @top_genres_count 10
  @top_artists_count 12
  @chart_count 5

  def index(conn, _params) do
    excluded_user_ids = conn.assigns[:ignoree_ids]

    top_songs_day    = Charts.top_songs_last_day(@chart_count, excluded_user_ids)
    top_songs_week   = Charts.top_songs_last_week(@chart_count, excluded_user_ids)
    top_upvoted_day  = Charts.top_upvoted_songs_last_day(@chart_count, excluded_user_ids)
    top_upvoted_week = Charts.top_upvoted_songs_last_week(@chart_count, excluded_user_ids)

    upvoted_song_ids =
      SongUpvoteService.upvoted_song_ids(
        current_resource(conn),
        Enum.concat([top_songs_day, top_songs_week, top_upvoted_day, top_upvoted_week])
      )

    render conn, "index.html",
      totals: Stats.totals(),
      top_genres: Stats.top_genres(@top_genres_count),
      top_artists: Stats.top_artists(@top_artists_count),
      listens_per_decade: Stats.listens_per_decade(),
      top_songs_day: top_songs_day,
      top_songs_week: top_songs_week,
      top_upvoted_day: top_upvoted_day,
      top_upvoted_week: top_upvoted_week,
      upvoted_song_ids: upvoted_song_ids
  end

  def genre(conn, %{"id" => id} = params) do
    tag = Repo.get!(Tag, id)

    songs =
      Song
      |> Song.for_genre(tag.id)
      |> Song.most_listened()
      |> paginate_songs(params)

    render(conn, "genre.html", tag: tag, songs: songs, upvoted_song_ids: upvoted_song_ids(conn, songs))
  end

  # Decades are addressed by their first year (/music/decades/1980). Any other
  # year inside the decade redirects to that canonical url, so a link built from
  # a song's release year still lands somewhere sensible, and anything that is
  # not a plausible year is a 404 - the same answer an unknown genre gets.
  def decade(conn, %{"decade" => decade} = params) do
    case Integer.parse(decade) do
      {year, ""} when year in 1000..2999 ->
        start_year = div(year, 10) * 10

        if start_year == year do
          songs =
            Song
            |> Song.for_decade(start_year)
            |> Song.most_listened()
            |> paginate_songs(params)

          render(conn, "decade.html",
            decade: start_year,
            songs: songs,
            upvoted_song_ids: upvoted_song_ids(conn, songs))
        else
          redirect(conn, to: music_path(conn, :decade, start_year))
        end

      _ ->
        render_not_found(conn)
    end
  end

  def artist(conn, %{"artist_name" => segments} = params) do
    # Plug has already decoded each path segment, so rejoining them gives back
    # a name that was written with a slash in it.
    artist_name = Enum.join(segments, "/")
    artist = Artist.get_by_name(artist_name)

    songs =
      Song
      |> Song.for_artist_name(artist_name)
      |> Song.most_listened()
      |> paginate_songs(params)

    # An artist url only means something if the site knows the name, from a song
    # or from an enriched artist record; anything else is a made up url and gets
    # a 404 rather than an empty shell. total_entries is what is checked, not
    # the contents of this page, so a deep page number cannot turn a real artist
    # into a 404.
    if is_nil(artist) && songs.total_entries == 0 do
      render_not_found(conn)
    else
      render(conn, "artist.html",
        artist_name: display_artist_name(artist, songs, artist_name),
        artist: artist,
        listen_count: artist_listen_count(artist_name),
        songs: songs,
        upvoted_song_ids: upvoted_song_ids(conn, songs))
    end
  end

  # The header shows the artist's listens across their whole catalogue, not just
  # the songs on this page.
  defp artist_listen_count(artist_name) do
    Song
    |> Song.for_artist_name(artist_name)
    |> select([s], coalesce(sum(s.listens_count), 0))
    |> Repo.one()
  end

  # The shared song list partial renders {song, count} rows like the chart pages
  # do. These lists are ordered by the song's all time listen total, so that is
  # the number the rows show.
  defp paginate_songs(query, params) do
    page = capped_paginate(query, params)
    %{page | entries: Enum.map(page.entries, &{&1, &1.listens_count})}
  end

  defp upvoted_song_ids(conn, songs) do
    SongUpvoteService.upvoted_song_ids(current_resource(conn), songs)
  end

  # Prefer the enriched artist record's spelling, then the spelling on the songs
  # themselves; the name from the url is the last resort, since it is whatever
  # casing the visitor happened to type.
  defp display_artist_name(%Artist{} = artist, _songs, _artist_name), do: artist.name
  defp display_artist_name(nil, %{entries: [{song, _count} | _]}, _artist_name), do: song.artist_name
  defp display_artist_name(nil, _songs, artist_name), do: artist_name

  # A url that names no decade or no artist is a bad url, not a missing record,
  # so there is nothing for Repo.get! to raise about. The site's own 404 page is
  # rendered directly instead, and it is a standalone document, hence no layout.
  defp render_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(HelheimWeb.ErrorView)
    |> render("404.html", layout: false)
  end
end
