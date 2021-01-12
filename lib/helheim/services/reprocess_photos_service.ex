defmodule Helheim.ReprocessPhotosService do
  alias Helheim.Photo
  alias Helheim.Repo
  alias Helheim.Downloader
  alias HelheimWeb.PhotoFile

  import Ecto.Query, only: [from: 2]

  def reprocess_all() do
    query = from p in Photo, order_by: p.id
    EctoBatchStream.stream(Repo, query)
    |> Stream.chunk_every(3)
    |> Stream.each(fn(photos) ->
      photos
      |> Parallel.pmap(fn(photo) ->
        IO.inspect reprocess_one(photo)
      end)
    end)
    |> Stream.run()
  end

  def reprocess_one(photo) do
    with {:ok, url, download_path} <- extract_details(photo),
         {:ok, received_bytes} <- Downloader.download(url, download_path),
         {:ok, photo} <- reattach(photo, download_path),
         {:ok, _deletions} <- delete_download(download_path)
    do
      IO.inspect [photo, url, download_path, received_bytes]
      {:ok, photo, received_bytes}
    end
  end

  defp extract_details(photo) do
    url = PhotoFile.url({photo.file, photo}, :original, signed: true)
    download_file_name = photo.file.file_name |> Zarex.sanitize() |> String.replace(" ", "_")
    download_path = "#{File.cwd!}/tmp/reprocess/#{SecureRandom.uuid()}/#{download_file_name}"

    {:ok, url, download_path}
  end

  defp reattach(photo, download_path) do
    upload = %Plug.Upload{filename: photo.file.file_name, path: download_path}

    Photo.changeset(photo, %{file: upload})
    |> Repo.update()
  end

  defp delete_download(download_path) do
    Path.dirname(download_path)
    |> File.rm_rf()
  end
end
