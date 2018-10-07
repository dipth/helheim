defmodule HelheimWeb.Plug.LoadPendingFriendships do
  import Plug.Conn
  alias Helheim.Friendship

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user        = Guardian.Plug.current_resource(conn)
    friendships = Friendship.pending_friendships(user)

    conn
    |> assign(:pending_friendships, friendships)
    |> assign(:pending_friendships_count, length(friendships))
  end
end
