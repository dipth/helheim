# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :altnation,
  ecto_repos: [Altnation.Repo]

# Configures the endpoint
config :altnation, Altnation.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JXAQU/sDIXwY//LkAGR99f22MNDD4pO0vJUFeJFnX1JBTRsnG+UD/EbZpjVGoZb6",
  render_errors: [view: Altnation.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Altnation.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure guardian
config :guardian, Guardian,
  issuer: "Altnation",
  ttl: { 1, :day },
  verify_issuer: true,
  serializer: Altnation.GuardianSerializer

# Configure Sentry
config :sentry,
  environment_name: Mix.env,
  included_environments: [:prod]

# Configure Appsignal
config :appsignal, :config,
  active: false,
  name: :altnation,
  push_api_key: "only_applicable_in_production",
  env: Mix.env
config :altnation, Altnation.Endpoint,
  instrumenters: [Appsignal.Phoenix.Instrumenter]
config :phoenix, :template_engines,
  eex: Appsignal.Phoenix.Template.EExEngine,
  exs: Appsignal.Phoenix.Template.ExsEngine
config :altnation, Altnation.Repo,
  loggers: [Appsignal.Ecto]

# Configure mailer
config :altnation, Altnation.Mailer,
  adapter: Bamboo.PostmarkAdapter,
  api_key: "only_applicable_in_production"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
