defmodule HelheimWeb.SongController do
  use HelheimWeb, :controller
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

  def show(conn, %{"id" => id}) do
    song = Repo.get!(Song, id)
    recent_listens =
      SongListen
      |> SongListen.for_song(song)
      |> SongListen.newest
      |> preload(:user)
      |> limit(10)
      |> Repo.all
    render(conn, "show.html", song: song, recent_listens: recent_listens)
  end
end
