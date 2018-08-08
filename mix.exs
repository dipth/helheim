defmodule Helheim.Mixfile do
  use Mix.Project

  def project do
    [app: :helheim,
     version: "0.0.1",
     elixir: "~> 1.4",
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
                    :phoenix_ecto, :postgrex, :comeonin, :bamboo, :calendar, :sentry, :scout_apm,
                    :ex_aws, :hackney, :poison, :timex, :scrivener_html, :timex_ecto,
                    :stripity_stripe, :recaptcha]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.3"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_ecto, "~> 3.0"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:comeonin, "~> 4.0"},
     {:bcrypt_elixir, "~> 0.12.0"},
     {:pbkdf2_elixir, "~> 0.12"},
     {:guardian, "~> 0.14"},
     {:secure_random, "~> 0.5.0"},
     {:bamboo, "~> 0.7"},
     {:bamboo_postmark, "~> 0.4.1"},
     {:calendar, "~> 0.17"},
     {:calendar_translations, "~> 0.0.4"},
     {:calecto, "~> 0.16.0"},
     {:timex, "~> 3.0"},
     {:timex_ecto, "~> 3.0"},
     {:wallaby, "~> 0.20.0", [runtime: false, only: :test]},
     {:ex_machina, "~> 2.0", only: :test},
     {:sentry, "~> 5.0.1"},
     {:arc, "~> 0.8.0"},
     {:arc_ecto, "~> 0.7.0"},
     {:hackney, "~> 1.9", override: true},# Used by arc
     {:ex_aws, "~> 1.1.3"},               # Used by arc
     {:poison, "~> 3.1"},                 # Used by arc
     {:sweet_xml, "~> 0.6"},              # Used by arc
     {:html_sanitize_ex, "~> 1.1"},
     {:crutches, "~> 1.0.0"},
     {:scrivener_ecto, "~> 1.1"}, # Pagination
     {:scrivener_html, "~> 1.1"}, # Pagination
     {:mock, "~> 0.3.1", only: :test},
     {:scout_apm, "~> 0.0"},
     {:stripity_stripe, "~> 1.6.0"},
     {:recaptcha, "~> 2.2"},
     {:remote_ip, "0.1.3"}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": [
        "assets.compile --quiet",
        "ecto.create --quiet",
        "ecto.migrate",
        "test"
      ],
      "assets.compile": &compile_assets/1
    ]
  end

  defp compile_assets(_) do
    Mix.shell.cmd("brunch build")
  end
end
