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

  test "users can edit their own topics for a limited amount of time", %{session: session, user: user, forum: forum} do
    insert(:forum_topic, forum: forum, user: user, title: "Topic before edit")

    result = session
      |> visit("/forums/#{forum.id}")
      |> click_link("Topic before edit")
      |> click_link(gettext("Edit"))
      |> fill_in(gettext("Title"), with: "Topic after edit!")
      |> click_button(gettext("Save Changes"))
      |> find(".alert.alert-success")
      |> text

    assert result =~ gettext("Forum topic updated successfully.")
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

  test "users can edit their own replies for a limited amount of time", %{session: session, user: user, forum: forum} do
    topic = insert(:forum_topic, forum: forum)
    insert(:forum_reply, forum_topic: topic, user: user, body: "Reply before edit")

    result = session
      |> visit("/forums/#{forum.id}/forum_topics/#{topic.id}")
      |> click_link(gettext("Edit"))
      |> fill_in(gettext("Content"), with: "Reply after edit!")
      |> click_button(gettext("Save Changes"))
      |> find(".alert.alert-success")
      |> text

    assert result =~ gettext("Forum reply updated successfully.")
  end

  def create_forum(_context) do
    [forum: insert(:forum)]
  end
end
