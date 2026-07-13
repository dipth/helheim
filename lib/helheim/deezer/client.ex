defmodule Helheim.Deezer.Client do
  @moduledoc """
  Thin Req based client for Deezer's public API (no authentication), used
  as the fallback source for artist images when fanart.tv has none.
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

  defp find_exact_match(data, name) do
    data
    |> Enum.find(fn artist -> String.downcase(artist["name"] || "") == String.downcase(name) end)
    |> case do
      nil ->
        {:error, :not_found}
      artist ->
        {:ok, %{
          image_url_small: artist["picture_small"],
          image_url_medium: artist["picture_medium"],
          image_url_large: artist["picture_xl"]
        }}
    end
  end
end
