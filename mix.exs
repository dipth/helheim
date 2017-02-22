defmodule Helheim.Mixfile do
  use Mix.Project

  def project do
    [app: :helheim,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Helheim, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :postgrex, :comeonin, :bamboo, :calendar, :sentry,
                    :appsignal, :ex_aws, :hackney, :poison, :timex, :scrivener_html]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:comeonin, "~> 3.0"},
     {:guardian, "~> 0.14"},
     {:secure_random, "~> 0.5.0"},
     {:bamboo, "~> 0.7"},
     {:bamboo_postmark, "~> 0.2.0"},
     {:calendar, "~> 0.17"},
     {:calendar_translations, "~> 0.0.4"},
     {:calecto, "~> 0.16.0"},
     {:timex, git: "https://github.com/bitwalker/timex.git"},
     {:wallaby, "~> 0.15.0"},
     {:ex_machina, "~> 1.0", only: :test},
     {:sentry, "~> 2.1"},
     {:appsignal, "~> 0.0"},
     {:arc, "~> 0.6.0"},
     {:arc_ecto, "~> 0.5.0"},
     {:hackney, "1.6.5", override: true}, # Used by arc
     {:ex_aws, "~> 1.0.0"},               # Used by arc
     {:poison, "~> 2.0"},                 # Used by arc
     {:sweet_xml, "~> 0.5"},              # Used by arc
     {:html_sanitize_ex, "~> 1.1"},
     {:crutches, "~> 1.0.0"},
     {:scrivener_ecto, "~> 1.1"}, # Pagination
     {:scrivener_html, "~> 1.1"}, # Pagination
     {:mock, "~> 0.2.0", only: :test}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
