defmodule Helheim.Spotify.Client do
  @moduledoc """
  Thin Req based client for the Spotify OAuth and Web API endpoints used by
  the listening history feature. Configured via `config :helheim, :spotify`
  with `client_id`, `client_secret` and `redirect_uri`.
  """

  @accounts_url "https://accounts.spotify.com"
  @api_url "https://api.spotify.com/v1"
  @scope "user-read-recently-played"

  def authorize_url(state) do
    query = URI.encode_query(%{
      client_id: config()[:client_id],
      response_type: "code",
      redirect_uri: config()[:redirect_uri],
      scope: @scope,
      state: state
    })
    "#{@accounts_url}/authorize?#{query}"
  end

  def exchange_code(code) do
    token_request(%{grant_type: "authorization_code", code: code, redirect_uri: config()[:redirect_uri]})
  end

  def refresh(refresh_token) do
    token_request(%{grant_type: "refresh_token", refresh_token: refresh_token})
  end

  @doc """
  Fetches the authenticated user's Spotify profile. Used to store the Spotify
  user id when connecting an account.
  """
  def me(access_token) do
    case Req.get("#{@api_url}/me", auth: {:bearer, access_token}) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      other -> api_error(other)
    end
  end

  @doc """
  Fetches the user's recently played tracks. `after_cursor` is Spotify's
  millisecond based cursor; pass nil on the first poll.

  Returns `{:ok, %{items: items, next_after: cursor_or_nil}}`.
  """
  def recently_played(access_token, after_cursor \\ nil) do
    params = %{limit: 50}
    params = if after_cursor, do: Map.put(params, :after, after_cursor), else: params

    case Req.get("#{@api_url}/me/player/recently-played", params: params, auth: {:bearer, access_token}) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        next_after = case get_in(body, ["cursors", "after"]) do
          nil -> nil
          cursor when is_binary(cursor) -> String.to_integer(cursor)
          cursor when is_integer(cursor) -> cursor
        end
        {:ok, %{items: body["items"] || [], next_after: next_after}}
      other ->
        api_error(other)
    end
  end

  defp token_request(params) do
    case Req.post("#{@accounts_url}/api/token",
           body: URI.encode_query(params),
           headers: [{"content-type", "application/x-www-form-urlencoded"}],
           auth: {:basic, "#{config()[:client_id]}:#{config()[:client_secret]}"}
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}
      {:ok, %Req.Response{status: 400, body: %{"error" => "invalid_grant"}}} ->
        {:error, :invalid_grant}
      other ->
        api_error(other)
    end
  end

  defp api_error({:ok, %Req.Response{status: 401}}), do: {:error, :unauthorized}
  defp api_error({:ok, %Req.Response{status: 429} = resp}), do: {:error, {:rate_limited, retry_after(resp)}}
  defp api_error({:ok, %Req.Response{status: status, body: body}}), do: {:error, {:http_error, status, body}}
  defp api_error({:error, reason}), do: {:error, reason}

  defp retry_after(resp) do
    case Req.Response.get_header(resp, "retry-after") do
      [value | _] -> String.to_integer(value)
      _ -> 60
    end
  end

  defp config, do: Application.get_env(:helheim, :spotify)
end
