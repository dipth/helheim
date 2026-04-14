defmodule HelheimWeb.Endpoint do
  @session_options [
    store: :cookie,
    key: "_my_app_key",
    signing_salt: "somesigningsalt"
  ]

  use Phoenix.Endpoint, otp_app: :helheim

  if Application.compile_env(:helheim, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  # Cloudflare always sets CF-Connecting-IP to the real client IP, overwriting
  # any forged value. Using this single-value header avoids maintaining proxy
  # CIDR lists for Cloudflare and Fly.io in the X-Forwarded-For chain.
  plug RemoteIp, headers: ~w[cf-connecting-ip]

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId

  socket "/socket", HelheimWeb.UserSocket,
    websocket: [timeout: 45_000]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [timeout: 45_000, connect_info: [session: @session_options]]

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

  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason,
    length: 20_971_520 # 20 MB

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug HelheimWeb.Router
end
