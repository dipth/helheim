defmodule Helheim.ProfileBrowsingFlowTest do
  use Helheim.AcceptanceCase, async: true

  setup [:create_profile, :create_and_sign_in_user]

  test "users can browse recent profiles from the front page", %{profile: profile, session: session} do
    session
    |> click_link(profile.username)
  end

  test "users can browse the full list of comments on a profile", %{profile: profile, session: session} do
    session
    |> visit("/profiles/#{profile.id}")
    |> click_link(gettext("Show All"))
  end

  test "users can comment on a profile directly from the profile", %{profile: profile, session: session} do
    session
    |> visit("/profiles/#{profile.id}")

    result = session
    |> fill_in(gettext("Write new comment:"), with: "Super Duper Awesome Comment")
    |> click_on(gettext("Post Comment"))
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Comment created successfully")
    assert find(session, "p", text: "Super Duper Awesome Comment")
  end

  test "users can comment on a profile from the profiles guest book", %{profile: profile, session: session} do
    session
    |> visit("/profiles/#{profile.id}")
    |> click_link(gettext("Show All"))

    result = session
    |> fill_in(gettext("Write new comment:"), with: "Super Duper Awesome Comment")
    |> click_on(gettext("Post Comment"))
    |> find(".alert.alert-success")
    |> text

    assert result =~ gettext("Comment created successfully")
    assert find(session, "p", text: "Super Duper Awesome Comment")
  end

  defp create_profile(_context) do
    profile = insert(:user)
    [profile: profile]
  end
end
