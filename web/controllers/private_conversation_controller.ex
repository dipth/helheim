defmodule Helheim.PrivateConversationController do
  use Helheim.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.PrivateMessage

  def index(conn, params) do
    me = current_resource(conn)
    {messages, pagination} =
      PrivateMessage.unique_conversations_for(me)
      |> PrivateMessage.newest
      |> Repo.paginate(params, per_page: 10)
    messages = Repo.preload(messages, [:sender, :recipient])
    render(conn, "index.html", me: me, messages: messages, pagination: pagination)
  end

  def show(conn, params = %{"partner_id" => partner_id}) do
    me              = current_resource(conn)
    partner         = Repo.one!(from u in User, where: u.id == ^partner_id and u.id != ^me.id)
    conversation_id = PrivateMessage.calculate_conversation_id(me, partner)

    {messages, pagination} =
      PrivateMessage
      |> PrivateMessage.in_conversation(conversation_id)
      |> PrivateMessage.newest
      |> Repo.paginate(params, per_page: 10)
    messages = Repo.preload(messages, :sender)

    render(conn, "show.html", messages: messages, me: me, partner: partner, pagination: pagination)
  end
end
