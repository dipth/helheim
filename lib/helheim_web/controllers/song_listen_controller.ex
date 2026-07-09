defmodule HelheimWeb.SongListenController do
  use HelheimWeb, :controller
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.User

  plug :find_user
  plug HelheimWeb.Plug.EnforceBlock

  def index(conn, params) do
    user = conn.assigns[:user]

    listens =
      SongListen
      |> SongListen.for_user(user)
      |> SongListen.newest
      |> preload(:song)
      |> Repo.paginate(page: sanitized_page(params["page"]))

    top_songs = Song |> Song.top_for_user(user) |> limit(10) |> Repo.all
    top_artists = Song |> Song.top_artists_for_user(user) |> limit(10) |> Repo.all

    render(conn, "index.html", user: user, listens: listens, top_songs: top_songs, top_artists: top_artists)
  end

  defp find_user(conn, _) do
    assign conn, :user, Repo.get!(User, conn.params["profile_id"])
  end
end
