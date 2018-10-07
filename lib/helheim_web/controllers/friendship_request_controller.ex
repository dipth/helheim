defmodule HelheimWeb.FriendshipRequestController do
  use HelheimWeb, :controller
  alias Helheim.User
  alias Helheim.Friendship
  alias HelheimWeb.ErrorHelpers

  plug :scrub_get_params when action in [:create]
  plug :find_user when action in [:create]
  plug HelheimWeb.Plug.EnforceBlock when action in [:create]

  def create(conn, %{"profile_id" => _recipient_id}) do
    recipient = conn.assigns[:user]
    case Friendship.request_friendship!(current_resource(conn), recipient) do
      {:ok, _multi} ->
        conn
        |> put_flash(:success, gettext("A request has been sent!"))
        |> redirect(to: public_profile_path(conn, :show, recipient))
      {:error, :friendship, changeset, _changes_so_far} ->
        conn
        |> put_flash(
             :error,
             gettext(
               "Unable to send request: %{error}",
               error: ErrorHelpers.error_string_from_changeset(changeset)
             )
           )
        |> redirect(to: public_profile_path(conn, :show, recipient))
    end
  end

  def delete(conn, %{"profile_id" => sender_id}) do
    sender = Repo.get!(User, sender_id)
    case Friendship.reject_friendship!(current_resource(conn), sender) do
      {:ok, _friendship} ->
        conn
        |> put_flash(:success, gettext("The request has been rejected!"))
        |> redirect(to: friendship_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(
             :error,
             gettext(
               "Unable to reject request: %{error}",
               error: ErrorHelpers.error_string_from_changeset(changeset)
             )
           )
        |> redirect(to: friendship_path(conn, :index))
    end
  end

  defp find_user(conn, _) do
    user = Repo.get!(User, conn.params["profile_id"])
    assign conn, :user, user
  end
end
