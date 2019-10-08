use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :helheim, HelheimWeb.Endpoint,
  http: [port: 4001],
  server: true

config :helheim, :sql_sandbox, true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :helheim, Helheim.Repo,
  username: System.get_env("DATABASE_POSTGRESQL_USERNAME") || "postgres",
  password: System.get_env("DATABASE_POSTGRESQL_PASSWORD") || "postgres",
  database: "helheim_test",
  hostname: System.get_env("DATABASE_POSTGRESQL_HOSTNAME") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: 60_000,
  pool_timeout: 60_000

# Guardian configuration
config :helheim, Helheim.Auth.Guardian,
  secret_key: "MHtXjXB4jXOtVQAJE39RxEaHOPj8jJiAI5HLW+p8xC1IeUcnc+T81t9KiC/9a4wh"

# Make password hashing faster during tests
config :bcrypt_elixir, :log_rounds, 4
config :pbkdf2_elixir, :rounds, 1

# Configure mailer
config :helheim, Helheim.Mailer,
  adapter: Bamboo.TestAdapter

# Configure arc
config :arc,
  storage: Arc.Storage.Local

# Configure Stripe
config :helheim, :stripe,
  public_key: "pk_test_abababababababababababab"
config :stripity_stripe,
  secret_key: "sk_test_abababababababababababab"

# Configure ReCaptcha
config :recaptcha,
  public_key: "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI",
  secret: "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"

# Configure wallaby
config :wallaby,
  driver: Wallaby.Experimental.Chrome
