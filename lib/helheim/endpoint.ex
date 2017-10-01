defmodule Helheim.Endpoint do
  use Phoenix.Endpoint, otp_app: :helheim

  plug Plug.CloudFlare

  socket "/socket", Helheim.UserSocket

  if Application.get_env(:helheim, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :helheim, gzip: false,
    only: ~w(
      css fonts images js sounds robots.txt android-chrome-192x192.png
      apple-touch-icon.png browserconfig.xml favicon-16x16.png favicon-32x32.png
      favicon.ico manifest.json mstile-150x150.png safari-pinned-tab.svg
      .well-known
    )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_helheim_key",
    signing_salt: "ihhWS/9O"

  plug Helheim.Router
end
