defmodule Guardian.Plug.VerifyRememberMe do
  @moduledoc """
  Use this plug to load a remember me cookie and convert it into an access token

  ## Example

      plug Guardian.Plug.VerifyRememberMe

  This should be run after Guardian.Plug.VerifySession

  It assumes that there is a cookie called 'remember_me' and that it has a
  refresh type token
  """

  @doc false
  def init(opts \\ %{}), do: Enum.into(opts, %{})

  @doc false
  def call(conn, _) do
    if Guardian.Plug.authenticated?(conn) do
      # we're already authenticated somehow either from the session or header
      conn
    else
      # do we find a cookie
      jwt = conn.req_cookies["remember_me"]  # options could specify this
      case exchange!(jwt, "refresh") do # options could specify these too
        {:ok, resource} ->
          HelheimWeb.Auth.login(conn, resource)
        _error -> conn
      end
    end
  end

  # this function could go into guardian itself
  defp exchange!(nil, _), do: {:error, :not_found}
  defp exchange!(jwt, from) do
    case Guardian.decode_and_verify(jwt, typ: from) do # only accept remember me tokens of type "refresh"
      { :ok, claims } ->
        new_claims = claims
          |> Map.drop(["jti", "iat", "exp", "nbf"])
          |> Guardian.Claims.jti
          |> Guardian.Claims.nbf
          |> Guardian.Claims.iat
          |> Guardian.Claims.ttl

        Guardian.serializer.from_token(new_claims["sub"])
      error -> error
    end
  end
end
