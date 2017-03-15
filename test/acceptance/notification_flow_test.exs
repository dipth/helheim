defmodule Helheim.NotificationFlowTest do
  use Helheim.AcceptanceCase#, async: true

  setup [:create_and_sign_in_user]

  test "users can see and click notifications from the header", %{session: session, user: user} do
    insert(:notification, user: user, title: "Super Notification!", path: "/profiles/#{user.id}")

    session
    |> visit("/front_page")

    assert find(session, Query.css("#nav-item-notifications .badge", text: "1"))

    session
    |> click(Query.css("#nav-link-notifications"))
    |> click(Query.link("Super Notification!"))

    assert current_path(session) == "/profiles/#{user.id}"
  end
end
