defmodule HelheimWeb.LayoutView do
  use HelheimWeb, :view
  alias Helheim.Repo
  alias Helheim.User

  def meta_usernames do
    User.all_usernames
    |> Enum.join(",")
  end
end
