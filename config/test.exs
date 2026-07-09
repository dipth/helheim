import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :helheim, HelheimWeb.Endpoint,
  http: [port: 4001],
  server: true

config :helheim, :sql_sandbox, true

# Create notifications synchronously so background tasks don't outlive the
# test process and race with the SQL sandbox
config :helheim, :async_notifications, false

# Run Oban in manual testing mode so jobs only execute through Oban.Testing
config :helheim, Oban, testing: :manual

# Print only warnings and errors during test
config :logger, level: :warning

# Configure your database
config :helheim, Helheim.Repo,
  username: System.get_env("DATABASE_POSTGRESQL_USERNAME") || "postgres",
  password: System.get_env("DATABASE_POSTGRESQL_PASSWORD") || "postgres",
  database: "helheim_test",
  hostname: System.get_env("DATABASE_POSTGRESQL_HOSTNAME") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: 60_000

# Guardian configuration
config :helheim, Helheim.Auth.Guardian,
  secret_key: "MHtXjXB4jXOtVQAJE39RxEaHOPj8jJiAI5HLW+p8xC1IeUcnc+T81t9KiC/9a4wh"

# Make password hashing faster during tests
config :bcrypt_elixir, :log_rounds, 4
config :pbkdf2_elixir, :rounds, 1

# Configure mailer
config :helheim, Helheim.Mailer,
  adapter: Bamboo.TestAdapter

# Configure waffle
config :waffle,
  storage: Waffle.Storage.Local

# Configure Stripe
config :helheim, :stripe,
  public_key: "pk_test_abababababababababababab"
config :stripity_stripe,
  secret_key: "sk_test_abababababababababababab"

# Configure ReCaptcha
config :helheim, :recaptcha,
  public_key: "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI",
  secret: "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe",
  test_mode: true

# Configure Last.fm
config :helheim, :lastfm,
  api_key: "lastfm_test_api_key",
  shared_secret: "lastfm_test_shared_secret",
  callback_url: "http://localhost:4001/lastfm_account/callback"

# Configure wallaby
config :wallaby,
  otp_app: :helheim,
  driver: Wallaby.Chrome
