defmodule HelheimWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :helheim,
    error_handler: HelheimWeb.Auth.ErrorHandler,
    module: Helheim.Auth.Guardian

  # If there is a remember-me cookie, validate it
  plug Guardian.Plug.VerifyCookie, claims: %{"typ" => "refresh"}

  # If there is a session token, validate it
  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}

  # If there is an authorization header, validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}

  # Load the user if either of the verifications worked
  plug Guardian.Plug.LoadResource, allow_blank: true
end
