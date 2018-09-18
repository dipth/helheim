defmodule HelheimWeb.ForumFlowTest do
  use HelheimWeb.AcceptanceCase#, async: true

  defp forums_link,         do: Query.link(gettext("Forums"))
  defp forum_link(forum),   do: Query.link(forum.title)
  defp title_field,         do: Query.text_field(gettext("Title"))
  defp content_field,       do: Query.text_field(gettext("Content"))
  defp success_alert,       do: Query.css(".alert.alert-success")
  defp edit_link,           do: Query.link(gettext("Edit"))
  defp save_changes_button, do: Query.button(gettext("Save Changes"))

  setup [:create_and_sign_in_user, :create_forum]

  test "users can post a new topic in a forum", %{session: session, forum: forum} do
    result = session
      |> click(forums_link())
      |> click(forum_link(forum))
      |> click(Query.link(gettext("Create new topic")))
      |> fill_in(title_field(), with: "What an awesome title!")
      |> fill_in(content_field(), with: "Best topic ever!")
      |> click(Query.button(gettext("Post Topic")))
      |> find(success_alert())
      |> Element.text

    assert result =~ gettext("Forum topic created successfully.")
  end

  test "users can edit their own topics for a limited amount of time", %{session: session, user: user, forum: forum} do
    insert(:forum_topic, forum: forum, user: user, title: "Topic before edit")

    result = session
      |> visit("/forums/#{forum.id}")
      |> click(Query.link("Topic before edit"))
      |> click(edit_link())
      |> fill_in(title_field(), with: "Topic after edit!")
      |> click(save_changes_button())
      |> find(success_alert())
      |> Element.text

    assert result =~ gettext("Forum topic updated successfully.")
  end

  test "users can reply to existing topics", %{session: session, forum: forum} do
    topic = insert(:forum_topic, forum: forum, title: "Existing topic")

    result = session
      |> click(forums_link())
      |> click(forum_link(forum))
      |> click(Query.link(topic.title))
      |> fill_in(content_field(), with: "Best reply ever!")
      |> click(Query.button(gettext("Post Reply")))
      |> find(success_alert())
      |> Element.text

    assert result =~ gettext("Reply created successfully")
  end

  test "users can edit their own replies for a limited amount of time", %{session: session, user: user, forum: forum} do
    topic = insert(:forum_topic, forum: forum)
    insert(:forum_reply, forum_topic: topic, user: user, body: "Reply before edit")

    result = session
      |> visit("/forums/#{forum.id}/forum_topics/#{topic.id}")
      |> click(edit_link())
      |> fill_in(content_field(), with: "Reply after edit!")
      |> click(save_changes_button())
      |> find(success_alert())
      |> Element.text

    assert result =~ gettext("Forum reply updated successfully.")
  end

  def create_forum(_context) do
    [forum: insert(:forum)]
  end
end
