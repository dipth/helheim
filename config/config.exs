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
  adapter: Bandit.PhoenixAdapter,
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

# Configure Oban
config :helheim, Oban,
  engine: Oban.Engines.Basic,
  repo: Helheim.Repo,
  queues: [lastfm: 5, enrichment: 1],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    # Rescue jobs orphaned in the executing state when their node dies -
    # Fly auto-stops idle machines mid-job (observed in production with an
    # enrichment job stuck executing for 48 minutes). 15 minutes is far
    # above any legitimate job runtime here.
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(15)},
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", Helheim.Lastfm.SchedulerWorker},
       {"30 * * * *", Helheim.Music.EnrichmentSweepWorker}
     ]}
  ]

# Configure MusicBrainz (identifying User-Agent required by their API terms)
config :helheim, :musicbrainz,
  user_agent: "Helheim/1.0 (https://www.helheim.dk; thomas@visioneers.dk)"

# Configure Sentry
config :sentry,
  environment_name: config_env()

# Configure mailer
config :helheim, Helheim.Mailer,
  adapter: Bamboo.PostmarkAdapter,
  api_key: "only_applicable_in_production"

# Configure calendar
config :calendar, :translation_module, CalendarTranslations.Translations

# Configure JSON library
config :phoenix,
  :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
