use Mix.Config

# For production, often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# SampleAppWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :helheim, HelheimWeb.Endpoint,
  load_from_system_env: true,
  url: [scheme: "https", host: System.get_env("HOST"), port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  check_origin: ["//helheim.dk", "//www.helheim.dk", "//staging.helheim.dk"],
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SALT")]

# Configure your database
config :helheim, Helheim.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

# Configure guardian
config :helheim, Helheim.Auth.Guardian,
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

# Configure mailer
config :helheim, Helheim.Mailer,
  api_key: System.get_env("POSTMARK_API_KEY")

# Configure Sentry
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  tags: %{
    env: "production"
  }

# Configure Scout APM
config :scout_apm,
  key: System.get_env("SCOUT_APM_KEY")

# Configure arc & AWS
config :arc,
  storage: Arc.Storage.S3,
  bucket: System.get_env("AWS_S3_BUCKET"),
  asset_host: System.get_env("AWS_S3_ASSET_HOST")

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION"),
  s3: [
    scheme: "https://",
    host: "s3.#{System.get_env("AWS_REGION")}.amazonaws.com",
    region: System.get_env("AWS_REGION")
  ]

# Configure Stripe
config :helheim, :stripe,
  public_key: System.get_env("STRIPE_PUBLIC_KEY")
config :stripity_stripe,
  secret_key: System.get_env("STRIPE_PRIVATE_KEY")

# Configure ReCaptcha
config :recaptcha,
  public_key: System.get_env("RECAPTCHA_PUBLIC_KEY"),
  secret: System.get_env("RECAPTCHA_SECRET_KEY")

# Filter sensitive data from logs
config :phoenix, :filter_parameters, ["password", "guardian_token"]

# Do not print debug messages in production
config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :helheim, HelheimWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :helheim, HelheimWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :helheim, HelheimWeb.Endpoint, server: true
#
