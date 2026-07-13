defmodule Helheim.Lastfm.Payload do
  @moduledoc """
  Shared parsing helpers for Last.fm API payloads, used by both the scrobble
  sync and the metadata enrichment paths so the two can never drift apart
  (e.g. one filtering the placeholder artwork and the other not).
  """

  # The image Last.fm serves when it has no real artwork.
  @placeholder_image_hash "2a96cbd8b46e442fc41c2b86b821562f"

  @doc """
  Picks the url of the image with the given size out of a Last.fm image
  array. Blank urls and the placeholder-star artwork count as no image.
  """
  def image_url(images, size) when is_list(images) do
    images
    |> Enum.find(fn image -> is_map(image) && image["size"] == size end)
    |> case do
      %{"#text" => url} when is_binary(url) -> url |> blank_to_nil() |> reject_placeholder()
      _ -> nil
    end
  end
  def image_url(_, _), do: nil

  @doc """
  Extracts tag names from a Last.fm tag container (`toptags` on tracks,
  `tags` on artists). Defensive against the API's inconsistent empty-value
  serializations (missing key, empty string, bare object).
  """
  def tag_names(%{"tag" => tags}) when is_list(tags) do
    tags
    |> Enum.map(fn
      %{"name" => name} -> name
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
  def tag_names(%{"tag" => %{"name" => name}}), do: [name]
  def tag_names(_), do: []

  def blank_to_nil(value) when is_binary(value) and value != "", do: value
  def blank_to_nil(_), do: nil

  defp reject_placeholder(nil), do: nil
  defp reject_placeholder(url) do
    if String.contains?(url, @placeholder_image_hash), do: nil, else: url
  end
end
