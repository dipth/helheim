defmodule HelheimWeb.UsernameView do
  use HelheimWeb, :view

  def render("index.json", %{usernames: usernames}) do
    render_many(usernames, HelheimWeb.UsernameView, "username.json")
  end

  def render("username.json", %{username: username}) do
    username.username
  end
end
