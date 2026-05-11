defmodule HelheimWeb.PhotoFile do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original, :large, :thumb, :nsfw_thumb]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)
  @magick_limits "-limit memory 64MiB -limit map 128MiB"
  @max_pixel_area 40_000_000

  def acl(:large, _), do: :public_read
  def acl(:thumb, _), do: :public_read
  def acl(:nsfw_thumb, _), do: :public_read

  def validate({file, photo}) do
    photo = Helheim.Repo.preload(photo, photo_album: :user)
    file_extension = file.file_name |> Path.extname |> String.downcase
    %{size: file_size} = File.stat!(file.path)

    Enum.member?(@extension_whitelist, file_extension) &&
      file_size <= current_max_file_size(photo.photo_album.user) &&
      within_pixel_limit?(file.path)
  end

  def transform(:large, _) do
    {:convert, "#{@magick_limits} -define jpeg:size=2400x2400 -auto-orient -strip -resize 1200x1200>"}
  end

  def transform(:thumb, _) do
    {:convert, "#{@magick_limits} -define jpeg:size=500x500 -auto-orient -strip -thumbnail 250x250^ -gravity center -extent 250x250"}
  end

  def transform(:nsfw_thumb, _) do
    {:convert, fn(input, output) ->
      overlay = Application.app_dir(:helheim, "priv/static/images/nsfw_overlay.png")
      "#{input} #{@magick_limits} -auto-orient -strip -thumbnail 250x250^ -gravity center -extent 250x250 -blur 0x20 #{overlay} -composite jpg:#{output}"
    end, :jpg}
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
    "https://placehold.it/250x250"
  end

  def default_url(:nsfw_thumb) do
    "https://placehold.it/250x250"
  end

  @doc """
  Checks whether the image at `path` has a pixel area (width * height) within
  the allowed limit. Uses ImageMagick `identify` which reads only the file
  header for JPEG/PNG/GIF, avoiding a full decode. The `[0]` suffix limits
  inspection to the first frame of animated GIFs.

  Returns `false` for unreadable files so they fail validation rather than
  proceeding to a potentially expensive transform.

  ## Examples

      iex> within_pixel_limit?("/tmp/small.jpg")  # 800x600 = 480_000
      true

      iex> within_pixel_limit?("/tmp/huge.png")   # 10000x10000 = 100_000_000
      false

  """
  @spec within_pixel_limit?(String.t()) :: boolean()
  defp within_pixel_limit?(path) do
    args = ["-limit", "memory", "64MiB", "-limit", "map", "128MiB",
            "-format", "%w %h", "#{path}[0]"]

    case System.cmd("identify", args, stderr_to_stdout: true) do
      {output, 0} ->
        parse_pixel_area(output)

      _ ->
        false
    end
  end

  @spec parse_pixel_area(String.t()) :: boolean()
  defp parse_pixel_area(output) do
    with [w_str, h_str] <- output |> String.trim() |> String.split(" ", parts: 2),
         {w, _} <- Integer.parse(w_str),
         {h, _} <- Integer.parse(h_str) do
      w * h <= @max_pixel_area
    else
      _ -> false
    end
  end

  defp current_max_file_size(user) do
    space_used  = Helheim.Photo.total_used_space_by user
    total_space = user.max_total_file_size
    space_left  = Enum.max [total_space - space_used, 0]
    Enum.min [space_left, Helheim.Photo.max_file_size()]
  end
end
