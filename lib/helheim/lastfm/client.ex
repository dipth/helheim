defmodule Helheim.Lastfm.Client do
  @moduledoc """
  Thin Req based client for the Last.fm web auth flow and API endpoints used
  by the listening history feature. Configured via `config :helheim, :lastfm`
  with `api_key` and `shared_secret`.

  Note that the Last.fm API usually reports errors as an HTTP 200 response
  with an `{"error": code, "message": ...}` body, so bodies are inspected
  before statuses.
  """

  alias Helheim.Lastfm.Payload

  @auth_url "https://www.last.fm/api/auth/"
  @api_url "https://ws.audioscrobbler.com/2.0/"

  @doc """
  The Last.fm authorization page url. The callback must be on the same host
  the user's browser session lives on, so the caller derives it from the
  current request rather than from static configuration.
  """
  def auth_url(callback_url) do
    query = URI.encode_query(%{api_key: config()[:api_key], cb: callback_url})
    "#{@auth_url}?#{query}"
  end

  @doc """
  Exchanges the one-time token from the auth callback for a session. Last.fm
  session keys have an infinite lifetime, so this is a one-time exchange with
  no refresh flow.
  """
  def get_session(token) do
    params = signed_params(%{method: "auth.getSession", api_key: config()[:api_key], token: token})

    case api_get(params) do
      {:ok, %{"session" => %{"name" => username, "key" => session_key}}} ->
        {:ok, %{username: username, session_key: session_key}}
      {:ok, body} ->
        {:error, {:unexpected_response, body}}
      error ->
        error
    end
  end

  @doc """
  Fetches the user's scrobbles. `from_uts` is a unix timestamp in seconds;
  only scrobbles after that time are returned. Pass nil to get the most
  recent page. The request is signed with the user's session key so that
  revoking access on Last.fm stops the tracking.

  Returns `{:ok, %{tracks: tracks}}` where tracks is always a list (the API
  returns a bare object when there is exactly one result).
  """
  def recent_tracks(username, session_key, from_uts \\ nil) do
    params = %{
      method: "user.getRecentTracks",
      api_key: config()[:api_key],
      user: username,
      limit: 200,
      sk: session_key
    }
    params = if from_uts, do: Map.put(params, :from, from_uts), else: params

    case api_get(signed_params(params)) do
      {:ok, %{"recenttracks" => recenttracks}} ->
        {:ok, %{tracks: List.wrap(recenttracks["track"])}}
      {:ok, body} ->
        {:error, {:unexpected_response, body}}
      error ->
        error
    end
  end

  @doc """
  Fetches extended metadata for a track: MusicBrainz ids, duration, album
  details and the top tags. Unsigned call; autocorrect follows Last.fm's
  canonical spelling of the artist/track.
  """
  def track_info(artist, title) do
    params = %{
      method: "track.getInfo",
      api_key: config()[:api_key],
      artist: artist,
      track: title,
      autocorrect: 1,
      format: "json"
    }

    case api_get(params) do
      {:ok, %{"track" => track}} -> {:ok, parse_track_info(track)}
      {:ok, body} -> {:error, {:unexpected_response, body}}
      {:error, :user_not_found} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Fetches an artist's MusicBrainz id and Last.fm url. The image data the
  endpoint returns is deliberately ignored - it has been a placeholder for
  all artists since 2019.
  """
  def artist_info(name) do
    params = %{
      method: "artist.getInfo",
      api_key: config()[:api_key],
      artist: name,
      autocorrect: 1,
      format: "json"
    }

    case api_get(params) do
      {:ok, %{"artist" => artist}} ->
        {:ok, %{mbid: Payload.blank_to_nil(artist["mbid"]), url: Payload.blank_to_nil(artist["url"]), tags: Payload.tag_names(artist["tags"])}}
      {:ok, body} ->
        {:error, {:unexpected_response, body}}
      {:error, :user_not_found} ->
        {:error, :not_found}
      error ->
        error
    end
  end

  defp parse_track_info(track) do
    album = if is_map(track["album"]), do: track["album"], else: %{}

    %{
      mbid: Payload.blank_to_nil(track["mbid"]),
      artist_mbid: Payload.blank_to_nil(get_in_map(track, "artist", "mbid")),
      album_mbid: Payload.blank_to_nil(album["mbid"]),
      album_name: Payload.blank_to_nil(album["title"]),
      duration_seconds: parse_duration(track["duration"]),
      image_extralarge: Payload.image_url(album["image"], "extralarge"),
      tags: Payload.tag_names(track["toptags"]),
      url: Payload.blank_to_nil(track["url"])
    }
  end

  # track.getInfo reports the duration in milliseconds, as a string, and
  # very often as "0" when unknown.
  defp parse_duration(duration) do
    case Integer.parse("#{duration}") do
      {ms, ""} when ms > 0 -> div(ms, 1000)
      _ -> nil
    end
  end

  defp get_in_map(map, key1, key2) do
    case map[key1] do
      %{} = inner -> inner[key2]
      _ -> nil
    end
  end

  # Signs the params with the api_sig required for authenticated calls:
  # md5 over the alphabetically sorted "<name><value>" pairs plus the shared
  # secret. The format param must not be part of the signature.
  defp signed_params(params) do
    signature_base =
      params
      |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
      |> Enum.map_join(fn {key, value} -> "#{key}#{value}" end)

    api_sig =
      :crypto.hash(:md5, signature_base <> config()[:shared_secret])
      |> Base.encode16(case: :lower)

    params
    |> Map.put(:api_sig, api_sig)
    |> Map.put(:format, "json")
  end

  defp api_get(params) do
    case Req.get(@api_url, params: params) do
      {:ok, %Req.Response{body: %{"error" => code} = body}} ->
        api_error(code, body["message"])
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}
      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp api_error(6, _message), do: {:error, :user_not_found}
  defp api_error(9, _message), do: {:error, :invalid_session}
  defp api_error(17, _message), do: {:error, :hidden_history}
  defp api_error(29, _message), do: {:error, :rate_limited}
  defp api_error(code, message), do: {:error, {:api_error, code, message}}

  defp config, do: Application.get_env(:helheim, :lastfm)
end
