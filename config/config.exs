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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
