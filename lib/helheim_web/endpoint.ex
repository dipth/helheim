defmodule HelheimWeb.Endpoint do
  @session_options [
    store: :cookie,
    key: "_my_app_key",
    signing_salt: "somesigningsalt"
  ]

  use Phoenix.Endpoint, otp_app: :helheim

  if Application.get_env(:helheim, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  plug RemoteIp, proxies: ~w[
    103.21.244.0/22
    103.22.200.0/22
    103.31.4.0/22
    104.16.0.0/12
    108.162.192.0/18
    131.0.72.0/22
    141.101.64.0/18
    162.158.0.0/15
    172.64.0.0/13
    173.245.48.0/20
    188.114.96.0/20
    190.93.240.0/20
    197.234.240.0/22
    198.41.128.0/17
  ]

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
    json_decoder: Poison,
    length: 20_971_520 # 20 MB

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug HelheimWeb.Router


  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
