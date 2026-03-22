import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("HOST") || "helheim.dk"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :helheim, HelheimWeb.Endpoint,
    url: [scheme: "https", host: host, port: 443],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    live_view: [signing_salt: System.get_env("LIVE_VIEW_SALT")]

  config :helheim, Helheim.Repo,
    url: System.get_env("NEON_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true,
    ssl_opts: [
      server_name_indication: to_charlist(System.get_env("NEON_HOST")),
      verify: :verify_none
    ]

  config :helheim, Helheim.Auth.Guardian,
    secret_key: System.get_env("GUARDIAN_SECRET_KEY")

  config :helheim, Helheim.Mailer,
    api_key: System.get_env("POSTMARK_API_KEY")

  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    tags: %{
      env: "production"
    }

  config :waffle,
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

  config :helheim, :stripe,
    public_key: System.get_env("STRIPE_PUBLIC_KEY")

  config :stripity_stripe,
    secret_key: System.get_env("STRIPE_PRIVATE_KEY")

  config :helheim, :recaptcha,
    public_key: System.get_env("RECAPTCHA_PUBLIC_KEY"),
    secret: System.get_env("RECAPTCHA_SECRET_KEY")
end
