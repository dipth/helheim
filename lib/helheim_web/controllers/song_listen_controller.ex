defmodule HelheimWeb.SongListenController do
  use HelheimWeb, :controller
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.User

  plug :find_user
  plug HelheimWeb.Plug.EnforceBlock

  def index(conn, params) do
    user = conn.assigns[:user]
    page = sanitized_page(params["page"])

    listens =
      SongListen
      |> SongListen.for_user(user)
      |> SongListen.newest
      |> preload(:song)
      |> Repo.paginate(page: page)

    # The top lists scan the user's entire history, so they are only
    # computed (and shown) on the first page
    {top_songs, top_artists} =
      if page == 1 do
        {
          Song |> Song.top_for_user(user) |> limit(10) |> Repo.all,
          Song |> Song.top_artists_for_user(user) |> limit(10) |> Repo.all
        }
      else
        {nil, nil}
      end

    render(conn, "index.html", user: user, listens: listens, top_songs: top_songs, top_artists: top_artists)
  end

  defp find_user(conn, _) do
    assign conn, :user, Repo.get!(User, conn.params["profile_id"])
  end
end
