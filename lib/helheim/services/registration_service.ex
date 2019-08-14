defmodule Helheim.RegistrationService do
  alias Helheim.User
  alias Helheim.NotificationSubscription
  alias Helheim.Repo

  def create!(params) do
    with {:ok, user} <- create_user(params),
         {:ok, _sub} <- create_notification_subscription(user)
    do
      {:ok, user}
    end
  end

  defp create_user(params) do
    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert()
  end

  defp create_notification_subscription(user) do
    NotificationSubscription.enable!(user, "comment", user)
  end
end
