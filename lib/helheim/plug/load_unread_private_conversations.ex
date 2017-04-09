defmodule Helheim.Plug.LoadUnreadPrivateConversations do
  import Plug.Conn
  alias Helheim.PrivateMessage

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _opts) do
    user          = Guardian.Plug.current_resource(conn)
    conversations = PrivateMessage.unread_conversations_for(user)
    conn
    |> assign(:unread_conversations, conversations)
    |> assign(:unread_conversations_count, length(conversations))
  end
end
