defmodule HelheimWeb.ProfileHelpers do
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import HelheimWeb.Gettext
  import HelheimWeb.Router.Helpers
  alias HelheimWeb.Endpoint
  alias Helheim.User
  alias HelheimWeb.Avatar
  alias Helheim.Donation

  def username(user), do: username(user, false)
  def username(nil, _), do: gettext("User deleted")
  def username(%User{} = user, false), do: [donor_badge(user), {:safe, user.username}, role_badge(user.role)]
  def username(%User{} = user, true), do: [donor_badge(user), link(user.username, to: public_profile_path(Endpoint, :show, user)), role_badge(user.role)]

  def username_with_avatar(user), do: username_with_avatar(user, false)
  def username_with_avatar(user, link), do: [username(user, link), {:safe, " "}, avatar(user)]

  def avatar_with_username(user), do: avatar_with_username(user, false)
  def avatar_with_username(user, link), do: Enum.reverse(username_with_avatar(user, link))

  def me?(conn, user), do: Guardian.Plug.current_resource(conn).id == user.id

  ### PRIVATE

  defp donor_badge(nil), do: {:safe, ""}
  defp donor_badge(user) do
    cond do
      Donation.recently_donated?(user) ->
        [
          img_tag(Endpoint.static_path("/images/donor_icon.png"), class: "donor-icon"),
          {:safe, [" "]}
        ]
      true ->
        {:safe, [""]}
    end
  end

  defp role_badge("admin"), do: [{:safe, " "}, content_tag(:span, "admin", class: "badge badge-default")]
  defp role_badge("mod"), do: [{:safe, " "}, content_tag(:span, "mod", class: "badge badge-default")]
  defp role_badge(_), do: {:safe, ""}

  defp avatar(nil), do: img_tag(static_path(Endpoint, "/images/deleted_user_avatar_tiny.png"), class: "img-avatar")
  defp avatar(%User{} = user), do: img_tag(Avatar.url({user.avatar, user}, :tiny), class: "img-avatar")
end
