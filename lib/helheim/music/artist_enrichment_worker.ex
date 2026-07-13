defmodule Helheim.Music.ArtistEnrichmentWorker do
  @moduledoc """
  Enriches an artist with a MusicBrainz id, country (nationality) and
  images. Images come from fanart.tv (by MusicBrainz id, community voted)
  with Deezer as the fallback source when fanart has nothing.

  MusicBrainz calls are paced cluster-wide through Helheim.Musicbrainz.paced/1.
  A force re-run re-resolves the mbid and country as well, so stale
  Last.fm-seeded ids can be corrected.
  """

  use Oban.Worker,
    queue: :enrichment,
    max_attempts: 5,
    unique: [
      period: 3600,
      keys: [:artist_id],
      states: [:available, :scheduled, :executing, :retryable, :suspended]
    ]

  require Logger
  alias Helheim.Repo
  alias Helheim.Artist
  alias Helheim.Lastfm
  alias Helheim.Musicbrainz
  alias Helheim.Fanart
  alias Helheim.Deezer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"artist_id" => artist_id} = args} = job) do
    artist = Repo.get(Artist, artist_id)

    cond do
      is_nil(artist) -> :ok
      artist.enriched_at && args["force"] != true -> :ok
      true -> artist |> enrich(args["force"] == true) |> settle_final_attempt(job, artist)
    end
  end

  defp settle_final_attempt({:error, reason}, %Oban.Job{attempt: attempt, max_attempts: max}, artist) when attempt >= max do
    Logger.error("Artist enrichment settled with error for artist #{artist.id}: #{inspect(reason)}")
    {:ok, _} = artist |> Artist.changeset(%{enriched_at: DateTime.utc_now()}) |> Repo.update()
    :ok
  end
  defp settle_final_attempt(result, _job, _artist), do: result

  defp enrich(artist, force) do
    with {:ok, artist} <- resolve_mbid(artist, force),
         {:ok, country_attrs} <- country_attrs(artist, force),
         {:ok, image_attrs} <- image_attrs(artist) do
      {:ok, _} =
        artist
        |> Artist.changeset(Map.merge(country_attrs, Map.put(image_attrs, :enriched_at, DateTime.utc_now())))
        |> Repo.update()

      :ok
    else
      {:error, :rate_limited} -> {:snooze, 60}
      {:error, reason} -> {:error, reason}
    end
  end

  # A force run re-resolves even a stored mbid so stale ids can heal; the
  # stored value is kept when re-resolution finds nothing.
  defp resolve_mbid(%Artist{mbid: mbid} = artist, false) when is_binary(mbid), do: {:ok, artist}
  defp resolve_mbid(artist, _force) do
    case mbid_from_lastfm(artist) || mbid_from_musicbrainz_search(artist) do
      {:error, :rate_limited} ->
        {:error, :rate_limited}
      nil ->
        {:ok, artist}
      mbid when is_binary(mbid) ->
        if mbid == artist.mbid do
          {:ok, artist}
        else
          artist |> Artist.changeset(%{mbid: mbid}) |> Repo.update()
        end
    end
  end

  defp mbid_from_lastfm(artist) do
    case Lastfm.Client.artist_info(artist.name) do
      {:ok, %{mbid: mbid}} -> mbid
      {:error, :rate_limited} -> {:error, :rate_limited}
      _ -> nil
    end
  end

  # Only a perfect-score, case-insensitively exact name match is accepted:
  # linking the wrong artist is worse than linking none.
  defp mbid_from_musicbrainz_search(%Artist{} = artist) do
    Musicbrainz.paced(fn -> Musicbrainz.Client.search_artist(artist.name) end)
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

  defp country_attrs(%Artist{mbid: nil}, _force), do: {:ok, %{}}
  defp country_attrs(%Artist{country_code: code}, false) when is_binary(code), do: {:ok, %{}}
  defp country_attrs(artist, _force) do
    Musicbrainz.paced(fn -> Musicbrainz.Client.artist(artist.mbid) end)
    |> case do
      {:ok, data} ->
        {:ok, %{country_code: country_code(data), country_name: get_in(data, ["area", "name"])}}
      {:error, :not_found} ->
        {:ok, %{}}
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

  defp image_attrs(artist) do
    case fanart_images(artist) || deezer_images(artist) do
      {:error, :rate_limited} -> {:error, :rate_limited}
      nil -> {:ok, %{}}
      attrs when is_map(attrs) -> {:ok, attrs}
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
end
