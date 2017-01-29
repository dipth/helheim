defmodule Helheim.PrivateMessageTest do
  use Helheim.ModelCase
  alias Helheim.PrivateMessage

  describe "calculate_conversation_id/2" do
    test "it returns a concatenation of the ids of both users in numerical order" do
      first_user = insert(:user)
      second_user = insert(:user)
      assert PrivateMessage.calculate_conversation_id(second_user, first_user) == "#{first_user.id}:#{second_user.id}"
      assert PrivateMessage.calculate_conversation_id(first_user, second_user) == "#{first_user.id}:#{second_user.id}"
    end
  end
end
