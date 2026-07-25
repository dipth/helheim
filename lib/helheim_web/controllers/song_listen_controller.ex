defmodule HelheimWeb.SongListenController do
  use HelheimWeb, :controller
  alias Helheim.Artist
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
          Song |> Song.top_artists_for_user(user) |> limit(10) |> Repo.all |> Artist.with_records()
        }
      else
        {nil, nil}
      end

    upvoted_song_ids =
      Helheim.SongUpvoteService.upvoted_song_ids(
        current_resource(conn),
        Enum.concat(top_songs || [], listens)
      )

    render(conn, "index.html",
      user: user,
      listens: listens,
      top_songs: top_songs,
      top_artists: top_artists,
      upvoted_song_ids: upvoted_song_ids)
  end

  defp find_user(conn, _) do
    assign conn, :user, Repo.get!(User, conn.params["profile_id"])
  end
end
