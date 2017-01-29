defmodule Helheim.PrivateMessageController do
  use Helheim.Web, :controller
  import Guardian.Plug, only: [current_resource: 1]
  alias Helheim.Repo
  alias Helheim.User
  alias Helheim.PrivateMessageService

  def create(conn, %{"private_conversation_partner_id" => partner_id, "private_message" => message_params}) do
    me      = current_resource(conn)
    partner = Repo.one!(from u in User, where: u.id == ^partner_id and u.id != ^me.id)
    result  = PrivateMessageService.insert(me, partner, message_params["body"])

    case result do
      {:ok, %{private_message: _private_message}} ->
        conn
        |> put_flash(:success, gettext("Message successfully sent"))
        |> redirect(to: private_conversation_path(conn, :show, partner))
      {:error, _failed_operation, _failed_value, _changes_so_far} ->
        conn
        |> put_flash(:error, gettext("Unable to send message"))
        |> redirect(to: private_conversation_path(conn, :show, partner))
    end
  end
end
