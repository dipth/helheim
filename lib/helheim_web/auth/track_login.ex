# TODO: Write some tests for this
defmodule HelheimWeb.Plug.TrackLogin do
  import Plug.Conn
  alias Helheim.Repo

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    with {:ok, id} <- get_id_from_session(conn),
         {:ok, conn, id} <- maybe_generate_new_id(conn, id),
         {:ok, user} <- load_user(conn),
         {:ok, _user} <- maybe_track_login(conn, user, id)
    do
      conn
    end
  end

  defp get_id_from_session(conn), do: {:ok, get_session(conn, :id)}

  defp maybe_generate_new_id(conn, nil) do
    id = SecureRandom.uuid
    conn = put_session(conn, :id, id)
    {:ok, conn, id}
  end
  defp maybe_generate_new_id(conn, id), do: {:ok, conn, id}

  defp load_user(conn), do: {:ok, Guardian.Plug.current_resource(conn)}

  defp maybe_track_login(_conn, %{incognito: true} = user, _id), do: {:ok, user}
  defp maybe_track_login(_conn, %{session_id: stored_id} = user, id) when stored_id == id, do: {:ok, user}
  defp maybe_track_login(conn, user, id) do
    changeset = Ecto.Changeset.change user,
      previous_login_at: user.last_login_at,
      previous_login_ip: user.last_login_ip,
      last_login_at:     DateTime.utc_now,
      last_login_ip:     remote_ip(conn),
      session_id:        id
    Repo.update(changeset)
  end

  defp remote_ip(conn), do: conn.remote_ip |> Tuple.to_list |> Enum.join(".")
end
