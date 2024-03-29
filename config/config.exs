# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :helheim, env: config_env()
config :helheim,
  ecto_repos: [Helheim.Repo]

# Configure Repo
config :helheim, Helheim.Repo,
  migration_timestamps: [type: :utc_datetime_usec]

# Configures the endpoint
config :helheim, HelheimWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JXAQU/sDIXwY//LkAGR99f22MNDD4pO0vJUFeJFnX1JBTRsnG+UD/EbZpjVGoZb6",
  live_view: [signing_salt: "A78RceomQzKIr7b0HfbmO8oE2lT24bnX"],
  render_errors: [view: HelheimWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Helheim.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id, :request_id]

# Configure guardian
config :helheim, Helheim.Auth.Guardian,
  issuer: "Helheim",
  ttl: { 1, :day },
  token_ttl: %{
    "refresh" => {30, :days},
    "access" =>  {1, :days}
  },
  verify_issuer: true

# Configure Sentry
config :sentry,
  environment_name: config_env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  json_library: Poison

# Configure mailer
config :helheim, Helheim.Mailer,
  adapter: Bamboo.PostmarkAdapter,
  api_key: "only_applicable_in_production"

# Configure calendar
config :calendar, :translation_module, CalendarTranslations.Translations

# Configure JSON
config :recaptcha,
  json_library: Poison
config :phoenix,
  :json_library, Poison

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
