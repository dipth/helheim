defmodule Helheim.PrivateConversationController do
  use Helheim.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.PrivateMessage

  def index(conn, params) do
    me = current_resource(conn)
    messages =
      PrivateMessage.unique_conversations_for(me)
      |> PrivateMessage.newest
      |> preload([:sender, :recipient])
      |> Repo.paginate(page: sanitized_page(params["page"]))
    render(conn, "index.html", me: me, messages: messages)
  end

  def show(conn, params = %{"partner_id" => partner_id}) do
    me              = current_resource(conn)
    partner         = Repo.one(from u in User, where: u.id == ^partner_id and u.id != ^me.id)
    conversation_id = PrivateMessage.calculate_conversation_id(me, partner || partner_id)

    PrivateMessage.mark_as_read!(conversation_id, me)

    messages =
      PrivateMessage
      |> PrivateMessage.in_conversation(conversation_id)
      |> PrivateMessage.newest
      |> preload(:sender)
      |> Repo.paginate(page: sanitized_page(params["page"]))

    conn
    |> Helheim.Plug.LoadUnreadPrivateConversations.call([]) # We need to reload unread conversations, otherwise the count could be off
    |> render("show.html", messages: messages, me: me, partner: partner)
  end
end
