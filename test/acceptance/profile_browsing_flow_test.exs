defmodule Helheim.ProfileBrowsingFlowTest do
  use Helheim.AcceptanceCase, async: true

  defp show_all_comments_link,  do: Query.css(".show-all-comments")
  defp comment_text_field,      do: Query.text_field(gettext("Write new comment:"))
  defp post_comment_button,     do: Query.button(gettext("Post Comment"))
  defp sucess_alert,            do: Query.css(".alert.alert-success")

  setup [:create_profile, :create_and_sign_in_user]

  test "users can browse recent profiles from the front page", %{profile: profile, session: session} do
    session
    |> click(Query.link(profile.username))
  end

  test "users can browse the full list of comments on a profile", %{profile: profile, session: session} do
    session
    |> visit("/profiles/#{profile.id}")
    |> click(show_all_comments_link())
  end

  test "users can comment on a profile directly from the profile", %{profile: profile, session: session} do
    session
    |> visit("/profiles/#{profile.id}")

    result = session
    |> fill_in(comment_text_field(), with: "Super Duper Awesome Comment")
    |> click(post_comment_button())
    |> find(sucess_alert())
    |> Element.text

    assert result =~ gettext("Comment created successfully")
    assert find(session, Query.text("Super Duper Awesome Comment"))
  end

  test "users can comment on a profile from the profiles guest book", %{profile: profile, session: session} do
    session
    |> visit("/profiles/#{profile.id}")
    |> click(show_all_comments_link())

    result = session
    |> fill_in(comment_text_field(), with: "Super Duper Awesome Comment")
    |> click(post_comment_button())
    |> find(sucess_alert())
    |> Element.text

    assert result =~ gettext("Comment created successfully")
    assert find(session, Query.text("Super Duper Awesome Comment"))
  end

  defp create_profile(_context) do
    profile = insert(:user)
    [profile: profile]
  end
end
