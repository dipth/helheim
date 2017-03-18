defmodule Helheim.ProfileHelpers do
  import Phoenix.HTML.Link
  import Phoenix.HTML.Tag
  import Helheim.Gettext
  import Helheim.Router.Helpers
  alias Helheim.Endpoint
  alias Helheim.User
  alias Helheim.Avatar

  def user_badge(nil, opts), do: user_badge(gettext("User deleted"), false, opts)
  def user_badge(%User{} = user, opts), do: user_badge(user.username, User.admin?(user), opts)
  def user_badge(username, is_admin, opts) do
    opts      = Keyword.merge([icon: "fa-user"], opts)
    css_class = "badge"
    text      = username

    {css_class, text} = if is_admin do
      {
        css_class <> " badge-primary",
        text      <> " (admin)"
      }
    else
      {
        css_class <> " badge-default",
        text
      }
    end

    text = if opts[:prefix] do
      opts[:prefix] <> text
    else
      text
    end

    text = if opts[:postfix] do
      text <> opts[:postfix]
    else
      text
    end

    content_tag :span, class: css_class do
      [
        content_tag(:i, "", class: "fa fa-fw #{opts[:icon]}"),
        {:safe, [" "]},
        {:safe, [text]}
      ]
    end
  end

  def username_with_avatar(nil, opts) do
    username = username_with_avatar(gettext("User deleted"), nil, false, opts)
    avatar   = img_tag(static_path(Endpoint, "/images/deleted_user_avatar_tiny.png"), class: "img-avatar")
    username_with_avatar(username, avatar, false, opts)
  end
  def username_with_avatar(%User{} = user, %{no_link: true} = opts) do
    username = user.username
    avatar   = img_tag(Avatar.url({user.avatar, user}, :tiny), class: "img-avatar")
    is_admin = User.admin?(user)
    username_with_avatar(username, avatar, is_admin, opts)
  end
  def username_with_avatar(%User{} = user, opts) do
    username = link(user.username, to: public_profile_path(Endpoint, :show, user))
    avatar   = link(img_tag(Avatar.url({user.avatar, user}, :tiny), class: "img-avatar"), to: public_profile_path(Endpoint, :show, user))
    is_admin = User.admin?(user)
    username_with_avatar(username, avatar, is_admin, opts)
  end
  def username_with_avatar(username, avatar, is_admin, opts) do
    opts = Map.merge(%{avatar_before_username: false}, opts)

    username = if is_admin do
      [
        username,
        {:safe, ["&nbsp;"]},
        content_tag(:span, "admin", class: "badge badge-primary")
      ]
    else
      [username]
    end

    result = [
      username,
      {:safe, ["&nbsp;"]},
      avatar
    ]

    result = if opts[:avatar_before_username] do
      Enum.reverse(result)
    else
      result
    end

    Enum.reject(result, fn(e) -> is_nil(e) end)
  end

  def me?(conn, user) do
    Guardian.Plug.current_resource(conn).id == user.id
  end
end
