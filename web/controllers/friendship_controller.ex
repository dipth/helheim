defmodule Helheim.FriendshipController do
  use Helheim.Web, :controller
  alias Helheim.Friendship
  alias Helheim.User
  alias Helheim.ErrorHelpers

  plug :scrub_get_params when action in [:index]
  plug :find_user when action in [:index]
  plug Helheim.Plug.EnforceBlock when action in [:index]

  def index(conn, params) do
    user                = conn.assigns[:user]
    active_friendships  = find_active_friendships(user, params)

    render(
      conn,
      "index.html",
      user: user,
      active_friendships: active_friendships
    )
  end

  def create(conn, %{"profile_id" => sender_id}) do
    sender = Repo.get!(User, sender_id)
    case Friendship.accept_friendship!(current_resource(conn), sender) do
      {:ok, _friendship} ->
        conn
        |> put_flash(:success, gettext("%{username} has been added to your contact list!", username: sender.username))
        |> redirect(to: friendship_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(
             :error,
             gettext(
               "Unable to accept request: %{error}",
               error: ErrorHelpers.error_string_from_changeset(changeset)
             )
           )
        |> redirect(to: friendship_path(conn, :index))
    end
  end

  def delete(conn, %{"profile_id" => friend_id}) do
    friend = Repo.get!(User, friend_id)
    case Friendship.cancel_friendship!(current_resource(conn), friend) do
      {:ok, _friendship} ->
        conn
        |> put_flash(:success, gettext("%{username} has been removed from your contact list!", username: friend.username))
        |> redirect(to: friendship_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(
             :error,
             gettext(
               "Unable to remove contact: %{error}",
               error: ErrorHelpers.error_string_from_changeset(changeset)
             )
           )
        |> redirect(to: friendship_path(conn, :index))
    end
  end

  defp find_user(conn, _) do
    user = if conn.params["profile_id"] do
      Repo.get!(User, conn.params["profile_id"])
    else
      current_resource(conn)
    end

    assign conn, :user, user
  end

  defp find_active_friendships(user, params) do
    Friendship
    |> Friendship.for_user(user)
    |> Friendship.accepted()
    |> preload([:sender, :recipient])
    |> Repo.paginate(page: sanitized_page(params["page"]))
  end
end
