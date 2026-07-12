defmodule Helheim.Lastfm.Client do
  @moduledoc """
  Thin Req based client for the Last.fm web auth flow and API endpoints used
  by the listening history feature. Configured via `config :helheim, :lastfm`
  with `api_key`, `shared_secret` and `callback_url`.

  Note that the Last.fm API usually reports errors as an HTTP 200 response
  with an `{"error": code, "message": ...}` body, so bodies are inspected
  before statuses.
  """

  @auth_url "https://www.last.fm/api/auth/"
  @api_url "https://ws.audioscrobbler.com/2.0/"

  def auth_url do
    query = URI.encode_query(%{api_key: config()[:api_key], cb: config()[:callback_url]})
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
