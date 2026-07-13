defmodule Helheim.Fanart.Client do
  @moduledoc """
  Thin Req based client for fanart.tv, used to fetch artist images by
  MusicBrainz artist id. Returns `{:error, :not_configured}` when no API
  key is set so callers can fall back to other image sources.
  """

  @api_url "https://webservice.fanart.tv/v3/music"

  @doc """
  Returns the highest voted artist thumb for the artist, both as the full
  size (1000px) url and as fanart's ~200px preview rendition.
  """
  def artist_images(mbid) do
    case config()[:api_key] do
      key when is_binary(key) and key != "" -> fetch_images(mbid, key)
      _ -> {:error, :not_configured}
    end
  end

  defp fetch_images(mbid, api_key) do
    case Req.get("#{@api_url}/#{mbid}", params: %{api_key: api_key}) do
      {:ok, %Req.Response{status: 200, body: %{"artistthumb" => [_ | _] = thumbs}}} ->
        case Enum.max_by(thumbs, &likes/1) do
          %{"url" => url} when is_binary(url) and url != "" ->
            {:ok, %{thumb_url: url, preview_url: preview_url(url)}}
          _ ->
            {:error, :not_found}
        end
      {:ok, %Req.Response{status: 200, body: _no_thumbs}} ->
        {:error, :not_found}
      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}
      {:ok, %Req.Response{status: 429}} ->
        {:error, :rate_limited}
      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp likes(thumb) do
    case Integer.parse("#{thumb["likes"]}") do
      {likes, ""} -> likes
      _ -> 0
    end
  end

  defp preview_url(nil), do: nil
  defp preview_url(url), do: String.replace(url, "/fanart/", "/preview/")

  defp config, do: Application.get_env(:helheim, :fanart, [])
end
