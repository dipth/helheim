defmodule Helheim.PrivateMessage do
  use Helheim.Web, :model
  alias Helheim.Repo
  alias Helheim.PrivateMessage
  alias Helheim.User

  schema "private_messages" do
    field      :conversation_id, :string
    belongs_to :sender,          Helheim.User
    belongs_to :recipient,       Helheim.User
    field      :body,            :string

    timestamps()
  end

  def create_changeset(struct, sender, recipient, params \\ %{}) do
    struct
    |> cast(params, [:body])
    |> trim_fields([:body])
    |> put_assoc(:sender, sender)
    |> put_assoc(:recipient, recipient)
    |> put_change(:conversation_id, calculate_conversation_id(sender, recipient))
    |> validate_required([:conversation_id, :sender, :recipient, :body])
  end

  def newest(query) do
    from m in query,
    order_by: [desc: m.inserted_at]
  end

  def in_conversation(query, conversation_id) do
    from m in query,
    where: m.conversation_id == ^conversation_id
  end

  def by_or_for(query, user) do
    from m in query,
    where: m.sender_id == ^user.id or m.recipient_id == ^user.id
  end

  def unique_conversations_for(user) do
    from m in PrivateMessage,
      where: m.id in(^last_conversation_msg_ids_for(user))
  end

  def calculate_conversation_id(user_1 = %User{}, user_2 = %User{}), do: calculate_conversation_id(user_1.id, user_2.id)
  def calculate_conversation_id(user_1 = %User{}, user_2_id), do: calculate_conversation_id(user_1.id, user_2_id)
  def calculate_conversation_id(user_1_id, user_2 = %User{}), do: calculate_conversation_id(user_1_id, user_2.id)
  def calculate_conversation_id(user_1_id, user_2_id) do
    [user_1_id, user_2_id]
    |> Enum.sort()
    |> Enum.join(":")
  end

  def partner(message, you) do
    cond do
      message.sender_id && message.recipient_id && message.sender_id == you.id ->
        message.recipient
      message.sender_id && message.recipient_id && message.recipient_id == you.id ->
        message.sender
      true ->
        message.conversation_id
        |> String.split(":")
        |> Enum.map(fn(str_id) -> String.to_integer(str_id) end)
        |> Enum.find(fn(id) -> id != you.id end)
    end
  end

  defp last_conversation_msg_ids_for(user) do
    PrivateMessage
    |> by_or_for(user)
    |> group_by([m], m.conversation_id)
    |> select([m], max(m.id))
    |> Repo.all
  end
end
