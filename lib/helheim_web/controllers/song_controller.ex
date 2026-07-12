defmodule HelheimWeb.SongController do
  use HelheimWeb, :controller
  alias Helheim.Block
  alias Helheim.Comment
  alias Helheim.Song
  alias Helheim.SongListen
  alias Helheim.Music.Charts

  def index(conn, params) do
    songs =
      Song
      |> Song.top_by_listens_since(Charts.start_of_week(), conn.assigns[:ignoree_ids])
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", songs: songs)
  end

  def show(conn, %{"id" => id} = params) do
    song = Repo.get!(Song, id)
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

  def remove_my_listens(conn, %{"song_id" => song_id}) do
    song = Repo.get!(Song, song_id)
    {:ok, _} = Helheim.LastfmAccountService.delete_listens_for_song!(current_resource(conn), song)

    conn
    |> put_flash(:success, gettext("Your listens have been removed from this song."))
    |> redirect(to: song_path(conn, :show, song))
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
