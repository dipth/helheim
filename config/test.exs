use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :altnation, Altnation.Endpoint,
  http: [port: 4001],
  server: true

config :altnation, :sql_sandbox, true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :altnation, Altnation.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATABASE_POSTGRESQL_USERNAME") || "postgres",
  password: System.get_env("DATABASE_POSTGRESQL_PASSWORD") || "postgres",
  database: "altnation_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Make password hashing faster during tests
config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1

config :altnation, :secret_key_passphrase, "password"
config :altnation, :secret_key, File.read!("priv/repo/dev.jwk")

config :altnation, Altnation.Mailer,
  adapter: Bamboo.TestAdapter
