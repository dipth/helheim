defmodule HelheimWeb.SongController do
  use HelheimWeb, :controller
  alias Helheim.Comment
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.Spotify.Charts

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
    render(conn, "show.html", song: song, recent_listens: recent_listens, comments: comments)
  end
end
