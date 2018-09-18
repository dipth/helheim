defmodule Helheim.PrivateMessage do
  use Helheim, :model

  alias Helheim.Repo
  alias Helheim.PrivateMessage
  alias Helheim.User

  schema "private_messages" do
    field      :conversation_id,        :string
    field      :body,                   :string
    field      :read_at,                Calecto.DateTimeUTC
    field      :hidden_by_sender_at,    Calecto.DateTimeUTC
    field      :hidden_by_recipient_at, Calecto.DateTimeUTC

    timestamps()

    belongs_to :sender,          Helheim.User
    belongs_to :recipient,       Helheim.User
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
    where:
      (m.sender_id == ^user.id and is_nil(m.hidden_by_sender_at)) or
      (m.recipient_id == ^user.id and is_nil(m.hidden_by_recipient_at))
  end

  def unique_conversations_for(user) do
    from m in PrivateMessage,
      where: m.id in(^last_conversation_msg_ids_for(user))
  end

  def unread_conversations_for(recipient) do
    sq = from(
      sub_msg in PrivateMessage,
      select:   %{id: max(sub_msg.id)},
      where:    sub_msg.recipient_id == ^recipient.id and is_nil(sub_msg.read_at),
      group_by: sub_msg.conversation_id
    )
    from(
      msg in PrivateMessage,
      join:     sub_msg in subquery(sq), on: msg.id == sub_msg.id,
      join:     usr in User, on: usr.id == msg.sender_id,
      select:   %{conversation_id: msg.conversation_id, sender_id: msg.sender_id, body: msg.body, username: usr.username},
      order_by: [desc: msg.inserted_at]
    )
    |> Repo.all
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

  def unread?(message, recipient) do
    message.read_at == nil && message.recipient_id == recipient.id
  end

  def mark_as_read!(conversation_id, recipient) do
    from(
      m in PrivateMessage,
      where: m.conversation_id == ^conversation_id and m.recipient_id == ^recipient.id,
      update: [set: [read_at: ^DateTime.utc_now]]
    ) |> Repo.update_all([])
  end

  def hide!(conversation_id, %{recipient: recipient}) do
    from(
      m in PrivateMessage,
      where: m.conversation_id == ^conversation_id and m.recipient_id == ^recipient.id,
      update: [set: [hidden_by_recipient_at: ^DateTime.utc_now]]
    ) |> Repo.update_all([])
  end

  def hide!(conversation_id, %{sender: sender}) do
    from(
      m in PrivateMessage,
      where: m.conversation_id == ^conversation_id and m.sender_id == ^sender.id,
      update: [set: [hidden_by_sender_at: ^DateTime.utc_now]]
    ) |> Repo.update_all([])
  end

  def hide!(conversation_id, %{user: user}) do
    with {num1, _} <- hide!(conversation_id, %{recipient: user}),
         {num2, _} <- hide!(conversation_id, %{sender: user}),
      do: {:ok, num1 + num2}
  end

  defp last_conversation_msg_ids_for(user) do
    PrivateMessage
    |> by_or_for(user)
    |> group_by([m], m.conversation_id)
    |> select([m], max(m.id))
    |> Repo.all
  end
end
