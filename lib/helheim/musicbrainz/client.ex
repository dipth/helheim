defmodule Helheim.Musicbrainz.Client do
  @moduledoc """
  Thin Req based client for the MusicBrainz API, used to enrich songs and
  artists with release years and countries.

  MusicBrainz allows one request per second per IP and requires a
  meaningful User-Agent; callers (the enrichment workers) are responsible
  for pacing their calls accordingly.
  """

  @api_url "https://musicbrainz.org/ws/2"

  def artist(mbid) do
    get("/artist/#{mbid}", %{})
  end

  def search_artist(name) do
    case get("/artist", %{query: ~s(artist:"#{escape(name)}"), limit: 5}) do
      {:ok, %{"artists" => artists}} when is_list(artists) -> {:ok, artists}
      {:ok, body} -> {:error, {:unexpected_response, body}}
      error -> error
    end
  end

  def recording(mbid) do
    get("/recording/#{mbid}", %{})
  end

  # Last.fm album mbids are MusicBrainz *release* ids; the release year
  # lives on the associated release group.
  def release(mbid) do
    get("/release/#{mbid}", %{inc: "release-groups"})
  end

  def search_recording(artist, title) do
    query = ~s(recording:"#{escape(title)}" AND artist:"#{escape(artist)}" AND status:official)

    case get("/recording", %{query: query, limit: 5}) do
      {:ok, %{"recordings" => recordings}} when is_list(recordings) -> {:ok, recordings}
      {:ok, body} -> {:error, {:unexpected_response, body}}
      error -> error
    end
  end

  defp get(path, params) do
    params = Map.put(params, :fmt, "json")

    case Req.get(@api_url <> path, params: params, headers: [{"user-agent", config()[:user_agent]}]) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: 404}} -> {:error, :not_found}
      # Invalid/malformed mbids answer 400; treat like a miss so lookup
      # cascades continue with their fallbacks
      {:ok, %Req.Response{status: 400}} -> {:error, :not_found}
      {:ok, %Req.Response{status: 503}} -> {:error, :rate_limited}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp escape(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end

  defp config, do: Application.get_env(:helheim, :musicbrainz)
end
