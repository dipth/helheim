defmodule HelheimWeb.Avatar do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :large, :thumb, :tiny]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)
  @max_file_size 20 * 1024 * 1024 # MB

  def acl(:large, _), do: :public_read
  def acl(:thumb, _), do: :public_read
  def acl(:tiny, _), do: :public_read

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname |> String.downcase
    %{size: file_size} = File.stat!(file.path)
    Enum.member?(@extension_whitelist, file_extension) && file_size <= @max_file_size
  end

  def transform(:large, _) do
    {:convert, "-strip -resize 800x800^ -gravity center -extent 800x800"}
  end

  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250"}
  end

  def transform(:tiny, _) do
    {:convert, "-strip -thumbnail 50x50^ -gravity center -extent 50x50"}
  end

  def filename(version, _) do
    version
  end

  def storage_dir(_version, {_file, user}) do
    "uploads/avatars/#{user.id}"
  end

  def default_url(:large) do
    HelheimWeb.Router.Helpers.static_url(HelheimWeb.Endpoint, "/images/default_avatar.jpg")
  end

  def default_url(:thumb) do
    HelheimWeb.Router.Helpers.static_url(HelheimWeb.Endpoint, "/images/default_avatar.jpg")
  end

  def default_url(:tiny) do
    HelheimWeb.Router.Helpers.static_url(HelheimWeb.Endpoint, "/images/default_avatar_tiny.jpg")
  end

  def max_file_size do
    @max_file_size
  end
end
