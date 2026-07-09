defmodule HelheimWeb.SongController do
  use HelheimWeb, :controller
  alias Helheim.Comment
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.Music.Charts

  def index(conn, params) do
    songs =
      Song
      |> Song.top_by_listens_since(Charts.start_of_week())
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", songs: songs)
  end

  def show(conn, %{"id" => id} = params) do
    song = Repo.get!(Song, id)
    recent_listens =
      SongListen
      |> SongListen.for_song(song)
      |> SongListen.newest
      |> preload(:user)
      |> limit(10)
      |> Repo.all
    comments =
      assoc(song, :comments)
      |> Comment.not_deleted
      |> Comment.newest
      |> Comment.with_preloads
      |> Repo.paginate(page: sanitized_page(params["page"]))
    current_user_listen_count =
      SongListen
      |> SongListen.for_user(current_resource(conn))
      |> SongListen.for_song(song)
      |> Repo.aggregate(:count)
    render(conn, "show.html",
      song: song,
      recent_listens: recent_listens,
      comments: comments,
      current_user_listen_count: current_user_listen_count)
  end

  def remove_my_listens(conn, %{"song_id" => song_id}) do
    song = Repo.get!(Song, song_id)
    {:ok, _} = Helheim.SpotifyAccountService.delete_listens_for_song!(current_resource(conn), song)

    conn
    |> put_flash(:success, gettext("Your listens have been removed from this song."))
    |> redirect(to: song_path(conn, :show, song))
  end
end
