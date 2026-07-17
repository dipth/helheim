defmodule HelheimWeb.SongController do
  use HelheimWeb, :controller
  alias Helheim.Block
  alias Helheim.Cache
  alias Helheim.Comment
  alias Helheim.Deezer
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.Music.Charts

  # The full list pages are capped at 100 pages to preserve performance.
  @max_pages 100

  def recent(conn, params) do
    listens =
      SongListen
      |> SongListen.not_from_users(conn.assigns[:ignoree_ids])
      |> SongListen.latest_per_song
      |> SongListen.newest
      |> SongListen.with_preloads
      |> capped_paginate(params)
    render(conn, "recent.html", listens: listens)
  end

  def top_day(conn, params) do
    render_top(conn, params, Charts.hours_ago(24), gettext("Top songs, past 24 hours"))
  end

  def top_week(conn, params) do
    render_top(conn, params, Charts.hours_ago(24 * 7), gettext("Top songs, past 7 days"))
  end

  defp render_top(conn, params, since, title) do
    songs =
      Song
      |> Song.top_by_listens_since(since, conn.assigns[:ignoree_ids])
      |> capped_paginate(params)
    render(conn, "top.html", songs: songs, title: title)
  end

  def show(conn, %{"id" => id} = params) do
    song =
      Song
      |> Repo.get!(id)
      |> Repo.preload(song_tags: {Helheim.SongTag.ordered(Helheim.SongTag), [:tag]})
    current_user = current_resource(conn)
    recent_listens =
      SongListen
      |> SongListen.for_song(song)
      |> SongListen.newest
      |> SongListen.not_from_users(hidden_user_ids(conn, current_user))
      |> preload(:user)
      |> limit(10)
      |> Repo.all
    comments =
      assoc(song, :comments)
      |> Comment.not_deleted
      |> Comment.newest
      |> Comment.with_preloads
      |> Repo.paginate(page: sanitized_page(params["page"]))
    current_user_has_listens =
      SongListen
      |> SongListen.for_user(current_user)
      |> SongListen.for_song(song)
      |> Repo.exists?
    render(conn, "show.html",
      song: song,
      recent_listens: recent_listens,
      comments: comments,
      current_user_has_listens: current_user_has_listens)
  end

  # Redirects to a playable 30 second preview MP3. Deezer preview URLs
  # carry an expiring token, so only the track id is stored and the URL is
  # resolved (and briefly cached) on demand.
  def preview(conn, %{"song_id" => song_id}) do
    song = Repo.get!(Song, song_id)

    case resolve_preview_url(song) do
      {:ok, url} -> redirect(conn, external: url)
      _ -> send_resp(conn, :not_found, "")
    end
  end

  defp resolve_preview_url(%Song{deezer_id: nil}), do: :error
  defp resolve_preview_url(song) do
    Cache.fetch(
      {:deezer_preview, song.deezer_id},
      preview_url_cache_ttl(),
      fn -> Deezer.Client.track_preview_url(song.deezer_id) end,
      cache_if: &cacheable_preview_result?/1
    )
  end

  # Misses are cached too: a stale deezer_id (track since removed from
  # Deezer) would otherwise turn every click into a live Deezer call.
  # Transient failures (rate limits, outages) are not pinned.
  defp cacheable_preview_result?({:ok, _}), do: true
  defp cacheable_preview_result?({:error, :not_found}), do: true
  defp cacheable_preview_result?(_), do: false

  defp preview_url_cache_ttl do
    Application.get_env(:helheim, :preview_url_cache_ttl_ms, :timer.hours(1))
  end

  def remove_my_listens(conn, %{"song_id" => song_id}) do
    song = Repo.get!(Song, song_id)
    {:ok, _} = Helheim.LastfmAccountService.delete_listens_for_song!(current_resource(conn), song)

    conn
    |> put_flash(:success, gettext("Your listens have been removed from this song."))
    |> redirect(to: song_path(conn, :show, song))
  end

  defp capped_paginate(query, params) do
    query
    |> Repo.paginate(page: sanitized_page(params["page"], @max_pages))
    |> cap_total_pages(@max_pages)
  end

  # Users the viewer ignores, plus users who block the viewer, are left out
  # of the listener list - consistent with the rest of the site where
  # blockers are hidden from their blockees.
  defp hidden_user_ids(conn, current_user) do
    blocker_ids =
      Block
      |> Block.for_blockee(current_user)
      |> Block.enabled()
      |> select([b], b.blocker_id)
      |> Repo.all()

    blocker_ids ++ (conn.assigns[:ignoree_ids] || [])
  end
end
