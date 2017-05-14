defmodule Helheim.UsernameView do
  use Helheim.Web, :view

  def render("index.json", %{usernames: usernames}) do
    render_many(usernames, Helheim.UsernameView, "username.json")
  end

  def render("username.json", %{username: username}) do
    username.username
  end
end
