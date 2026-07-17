defmodule Helheim.Deezer.Client do
  @moduledoc """
  Thin Req based client for Deezer's public API (no authentication), used
  as the fallback source for artist images when fanart.tv has none, and as
  the source of 30 second song previews.
  """

  @api_url "https://api.deezer.com"

  @doc """
  Searches for the artist by name and returns its images, but only when a
  result matches the name case-insensitively - a fuzzy match would risk
  showing the wrong artist's photo.
  """
  def search_artist(name) do
    case Req.get("#{@api_url}/search/artist", params: %{q: name}) do
      {:ok, %Req.Response{body: %{"error" => %{"code" => 4}}}} ->
        {:error, :rate_limited}
      {:ok, %Req.Response{body: %{"error" => error}}} ->
        {:error, {:api_error, error["code"], error["message"]}}
      {:ok, %Req.Response{status: 200, body: %{"data" => data}}} when is_list(data) ->
        find_exact_match(data, name)
      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Searches for the track by artist and title and returns its Deezer id,
  but only for results whose artist matches case-insensitively and that
  actually have a preview - linking the wrong song is worse than linking
  none. Exact title matches win over Deezer's own relevance order, so
  "Battery" is not beaten by "Battery (Live)".
  """
  def search_track(artist_name, title) do
    query = ~s(artist:"#{strip_quotes(artist_name)}" track:"#{strip_quotes(title)}")

    case Req.get("#{@api_url}/search/track", params: %{q: query}) do
      {:ok, %Req.Response{body: %{"error" => %{"code" => 4}}}} ->
        {:error, :rate_limited}
      {:ok, %Req.Response{body: %{"error" => error}}} ->
        {:error, {:api_error, error["code"], error["message"]}}
      {:ok, %Req.Response{status: 200, body: %{"data" => data}}} when is_list(data) ->
        find_track_match(data, artist_name, title)
      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns a playable preview URL for the track. Deezer preview URLs carry
  an expiring hdnea token, so they must be resolved freshly rather than
  stored. Retries are disabled and the receive timeout is short because
  this call sits on a web request: Req's defaults (3 retries, 15s
  timeout) would pin the request process while Deezer is slow or down.
  """
  def track_preview_url(deezer_id) do
    case Req.get("#{@api_url}/track/#{deezer_id}", retry: false, receive_timeout: 5_000) do
      {:ok, %Req.Response{body: %{"error" => %{"code" => 4}}}} ->
        {:error, :rate_limited}
      # A deleted or unknown track id is a 200 with error code 800 ("no
      # data") - a miss rather than a failure, so callers can cache it.
      {:ok, %Req.Response{body: %{"error" => %{"code" => 800}}}} ->
        {:error, :not_found}
      {:ok, %Req.Response{body: %{"error" => error}}} ->
        {:error, {:api_error, error["code"], error["message"]}}
      {:ok, %Req.Response{status: 200, body: %{"preview" => preview}}} ->
        case present_url(preview) do
          nil -> {:error, :not_found}
          url -> {:ok, url}
        end
      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_track_match(data, artist_name, title) do
    candidates =
      Enum.filter(data, fn track ->
        String.downcase(get_in(track, ["artist", "name"]) || "") == String.downcase(artist_name) &&
          present_url(track["preview"])
      end)

    exact = Enum.find(candidates, fn track -> String.downcase(track["title"] || "") == String.downcase(title) end)

    case exact || List.first(candidates) do
      nil -> {:error, :not_found}
      track -> {:ok, %{deezer_id: track["id"]}}
    end
  end

  defp strip_quotes(value), do: String.replace(value, "\"", "")

  defp find_exact_match(data, name) do
    data
    |> Enum.find(fn artist -> String.downcase(artist["name"] || "") == String.downcase(name) end)
    |> case do
      nil ->
        {:error, :not_found}
      artist ->
        {:ok, %{
          image_url_small: present_url(artist["picture_small"]),
          image_url_medium: present_url(artist["picture_medium"]),
          image_url_large: present_url(artist["picture_xl"])
        }}
    end
  end

  defp present_url(url) when is_binary(url) and url != "", do: url
  defp present_url(_), do: nil
end
