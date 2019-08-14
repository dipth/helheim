defmodule Helheim.PhotoService do
  alias Helheim.Photo
  alias Helheim.NotificationSubscription
  alias Helheim.Repo

  def create!(user, album, file, nsfw) do
    with {:ok, photo} <- create_photo(album, file, nsfw),
         {:ok, _sub} <- create_notification_subscription(user, photo)
    do
      {:ok, photo}
    end
  end

  defp create_photo(album, file, nsfw) do
    file_stats = File.stat! file.path

    album
    |> Ecto.build_assoc(:photos)
    |> Photo.changeset(%{file: file, title: file.filename, nsfw: nsfw})
    |> Ecto.Changeset.put_change(:file_size, file_stats.size)
    |> Repo.insert()
  end

  defp create_notification_subscription(author, photo) do
    NotificationSubscription.enable!(author, "comment", photo)
  end
end
