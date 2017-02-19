defmodule Helheim.ForumFlowTest do
  use Helheim.AcceptanceCase

  setup [:create_and_sign_in_user, :create_forum]

  test "users can post a new topic in a forum", %{session: session, forum: forum} do
    result = session
      |> click_link(gettext("Forums"))
      |> click_link(forum.title)
      |> click_link(gettext("Create new topic"))
      |> fill_in(gettext("Title"), with: "What an awesome title!")
      |> fill_in(gettext("Content"), with: "Best topic ever!")
      |> click_button(gettext("Post Topic"))
      |> find(".alert.alert-success")
      |> text

    assert result =~ gettext("Forum topic created successfully.")
  end

  test "users can reply to existing topics", %{session: session, forum: forum} do
    topic = insert(:forum_topic, forum: forum, title: "Existing topic")

    result = session
      |> click_link(gettext("Forums"))
      |> click_link(forum.title)
      |> click_link(topic.title)
      |> fill_in(gettext("Content"), with: "Best reply ever!")
      |> click_button(gettext("Post Reply"))
      |> find(".alert.alert-success")
      |> text

    assert result =~ gettext("Reply created successfully")
  end

  def create_forum(_context) do
    [forum: insert(:forum)]
  end
end
