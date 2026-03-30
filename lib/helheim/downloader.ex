defmodule Helheim.Downloader do
  @moduledoc """
  Downloads files from URLs to local paths using Req.
  """

  @timeout 300_000

  @doc """
  Downloads the file at `url` to the local filesystem at `path`.

  Creates any necessary parent directories. Returns `{:ok, bytes_received}`
  on success or `{:error, reason}` on failure.

  ## Examples

      iex> Helheim.Downloader.download("https://example.com/file.jpg", "/tmp/file.jpg")
      {:ok, 12345}

  """
  @spec download(String.t(), String.t()) :: {:ok, non_neg_integer()} | {:error, String.t()}
  def download(url, path) do
    :ok = Path.dirname(path) |> File.mkdir_p()

    case Req.get(url, receive_timeout: @timeout, redirect: true, into: File.stream!(path)) do
      {:ok, %Req.Response{status: 200}} ->
        %{size: size} = File.stat!(path)
        {:ok, size}

      {:ok, %Req.Response{status: 404}} ->
        File.rm(path)
        {:error, "File not found"}

      {:ok, %Req.Response{status: code}} ->
        File.rm(path)
        {:error, "Received unexpected status code #{code}"}

      {:error, reason} ->
        File.rm(path)
        {:error, inspect(reason)}
    end
  end
end
