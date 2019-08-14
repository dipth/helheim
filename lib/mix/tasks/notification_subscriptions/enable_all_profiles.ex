defmodule Mix.Tasks.NotificationSubscriptions.EnableAllProfiles do
  use Mix.Task
  import Mix.Ecto
  alias Helheim.User
  alias Helheim.NotificationSubscription
  alias Helheim.Repo

  @shortdoc "Subscribe all existing users to notifications for comments on their profile"
  def run(_) do
    ensure_started(Repo, [])

    Repo.transaction(fn() ->
      User
      |> Repo.stream
      |> Enum.each(fn(user) ->
        NotificationSubscription.enable!(user, "comment", user)
        IO.puts "Enabled profile comments subscription for #{user.id}:#{user.username}"
      end)
    end)
  end
end
