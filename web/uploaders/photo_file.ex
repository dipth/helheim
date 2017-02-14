defmodule Helheim.PhotoFile do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :large, :thumb]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  def acl(:large, _), do: :public_read
  def acl(:thumb, _), do: :public_read

  def validate({file, photo}) do
    photo = Helheim.Repo.preload(photo, photo_album: :user)
    file_extension = file.file_name |> Path.extname |> String.downcase
    %{size: file_size} = File.stat!(file.path)
    Enum.member?(@extension_whitelist, file_extension) && file_size <= current_max_file_size(photo.photo_album.user)
  end

  def transform(:large, _) do
    {:convert, "-define jpeg:size=2400x2400 -strip -auto-orient -resize 1200x1200"}
  end

  def transform(:thumb, _) do
    {:convert, "-define jpeg:size=1000x1000 -strip -auto-orient -thumbnail 500x500^ -gravity center -extent 500x500"}
  end

  def filename(version, _) do
    version
  end

  def storage_dir(_version, {_file, photo}) do
    "uploads/photos/#{photo.uuid}"
  end

  def default_url(:large) do
    "https://placehold.it/1200x630"
  end

  def default_url(:thumb) do
    "https://placehold.it/500x500"
  end

  defp current_max_file_size(user) do
    space_used  = Helheim.Photo.total_used_space_by user
    total_space = Helheim.Photo.max_total_file_size_per_user
    space_left  = Enum.max [total_space - space_used, 0]
    Enum.min [space_left, Helheim.Photo.max_file_size()]
  end
end
