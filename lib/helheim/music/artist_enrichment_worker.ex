defmodule Helheim.Music.ArtistEnrichmentWorker do
  @moduledoc """
  Enriches an artist with a MusicBrainz id, country (nationality) and
  images. Images come from fanart.tv (by MusicBrainz id, community voted)
  with Deezer as the fallback source when fanart has nothing.

  Runs on the concurrency-1 :enrichment queue; see SongEnrichmentWorker
  for the MusicBrainz pacing rationale.
  """

  use Oban.Worker,
    queue: :enrichment,
    max_attempts: 5,
    unique: [period: 3600, keys: [:artist_id]]

  alias Helheim.Repo
  alias Helheim.Artist
  alias Helheim.Lastfm
  alias Helheim.Musicbrainz
  alias Helheim.Fanart
  alias Helheim.Deezer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"artist_id" => artist_id} = args}) do
    artist = Repo.get(Artist, artist_id)

    cond do
      is_nil(artist) -> :ok
      artist.enriched_at && args["force"] != true -> :ok
      true -> enrich(artist)
    end
  end

  defp enrich(artist) do
    with {:ok, artist} <- resolve_mbid(artist),
         {:ok, artist} <- apply_country(artist),
         {:ok, artist} <- apply_images(artist) do
      {:ok, _} =
        artist
        |> Artist.changeset(%{enriched_at: DateTime.utc_now()})
        |> Repo.update()

      :ok
    else
      {:error, :rate_limited} -> {:snooze, 60}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_mbid(%Artist{mbid: mbid} = artist) when is_binary(mbid), do: {:ok, artist}
  defp resolve_mbid(artist) do
    case mbid_from_lastfm(artist) || mbid_from_musicbrainz_search(artist) do
      {:error, :rate_limited} -> {:error, :rate_limited}
      nil -> {:ok, artist}
      mbid when is_binary(mbid) ->
        {:ok, artist} = artist |> Artist.changeset(%{mbid: mbid}) |> Repo.update()
        {:ok, artist}
    end
  end

  defp mbid_from_lastfm(artist) do
    case Lastfm.Client.artist_info(artist.name) do
      {:ok, %{mbid: mbid}} -> mbid
      _ -> nil
    end
  end

  # Only a perfect-score, case-insensitively exact name match is accepted:
  # linking the wrong artist is worse than linking none.
  defp mbid_from_musicbrainz_search(artist) do
    Musicbrainz.Client.search_artist(artist.name)
    |> musicbrainz_pause()
    |> case do
      {:ok, results} ->
        results
        |> Enum.find(fn result ->
          result["score"] == 100 && String.downcase(result["name"] || "") == String.downcase(artist.name)
        end)
        |> case do
          %{"id" => mbid} -> mbid
          _ -> nil
        end
      {:error, :rate_limited} ->
        {:error, :rate_limited}
      _ ->
        nil
    end
  end

  defp apply_country(%Artist{mbid: nil} = artist), do: {:ok, artist}
  defp apply_country(%Artist{country_code: code} = artist) when is_binary(code), do: {:ok, artist}
  defp apply_country(artist) do
    Musicbrainz.Client.artist(artist.mbid)
    |> musicbrainz_pause()
    |> case do
      {:ok, data} ->
        attrs = %{country_code: country_code(data), country_name: get_in(data, ["area", "name"])}
        {:ok, _} = artist |> Artist.changeset(attrs) |> Repo.update()
        {:ok, Repo.get(Artist, artist.id)}
      {:error, :not_found} ->
        {:ok, artist}
      error ->
        error
    end
  end

  defp country_code(data) do
    data["country"] ||
      case get_in(data, ["area", "iso-3166-1-codes"]) do
        [code | _] -> code
        _ -> nil
      end
  end

  defp apply_images(artist) do
    case fanart_images(artist) || deezer_images(artist) do
      {:error, :rate_limited} -> {:error, :rate_limited}
      nil -> {:ok, artist}
      attrs when is_map(attrs) ->
        {:ok, _} = artist |> Artist.changeset(attrs) |> Repo.update()
        {:ok, Repo.get(Artist, artist.id)}
    end
  end

  defp fanart_images(%Artist{mbid: nil}), do: nil
  defp fanart_images(artist) do
    case Fanart.Client.artist_images(artist.mbid) do
      {:ok, %{thumb_url: thumb, preview_url: preview}} ->
        %{image_url_small: preview, image_url_medium: preview, image_url_large: thumb, image_source: "fanart"}
      {:error, :rate_limited} ->
        {:error, :rate_limited}
      _ ->
        nil
    end
  end

  defp deezer_images(artist) do
    case Deezer.Client.search_artist(artist.name) do
      {:ok, images} ->
        Map.put(images, :image_source, "deezer")
      {:error, :rate_limited} ->
        {:error, :rate_limited}
      _ ->
        nil
    end
  end

  defp musicbrainz_pause(result) do
    Process.sleep(Helheim.Musicbrainz.pause_ms())
    result
  end
end
