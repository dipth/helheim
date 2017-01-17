defmodule Altnation.Avatar do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :thumb, :tiny]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)
  @max_file_size 1 * 1024 * 1024 # MB

  def acl(:thumb, _), do: :public_read
  def acl(:tiny, _), do: :public_read

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname |> String.downcase
    %{size: file_size} = File.stat!(file.path)
    Enum.member?(@extension_whitelist, file_extension) && file_size <= @max_file_size
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

  def storage_dir(version, {file, user}) do
    "uploads/avatars/#{user.id}"
  end

  def default_url(:thumb) do
    "https://placehold.it/250x250"
  end

  def default_url(:tiny) do
    "https://placehold.it/50x50"
  end

  def max_file_size do
    @max_file_size
  end
end
