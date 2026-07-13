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
          Song |> Song.top_artists_for_user(user) |> limit(10) |> Repo.all |> with_artist_records()
        }
      else
        {nil, nil}
      end

    render(conn, "index.html", user: user, listens: listens, top_songs: top_songs, top_artists: top_artists)
  end

  # Joins the aggregated {artist_name, count} rows with their enriched
  # artist records (images, nationality) in a single lookup. Songs whose
  # artist has not been enriched yet still appear, just without extras.
  defp with_artist_records([]), do: []
  defp with_artist_records(top_artists) do
    names = Enum.map(top_artists, fn {artist_name, _count} -> artist_name end)

    artists_by_name =
      Helheim.Artist
      |> Helheim.Artist.by_names(names)
      |> Repo.all()
      |> Map.new(fn artist -> {String.downcase(artist.name), artist} end)

    Enum.map(top_artists, fn {artist_name, count} ->
      {artist_name, count, artists_by_name[String.downcase(artist_name)]}
    end)
  end

  defp find_user(conn, _) do
    assign conn, :user, Repo.get!(User, conn.params["profile_id"])
  end
end
