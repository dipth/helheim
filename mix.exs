defmodule Helheim.Mixfile do
  use Mix.Project

  def project do
    [
      app: :helheim,
      version: "0.0.2",
      elixir: "~> 1.13.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Helheim.Application, []},
      extra_applications: [:logger, :runtime_tools, :recaptcha, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.0"},
      {:phoenix_pubsub, "~> 2.1.1"},
      {:phoenix_live_view, "~> 0.17.10"},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.6.5"},
      {:telemetry_poller, "~> 0.5.1"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:ecto_sql, "~> 3.8.3"},
      {:phoenix_ecto, "~> 4.4.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.2.0"},
      {:phoenix_live_reload, "~> 1.3.3", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.4"},
      {:cowlib, "~> 2.8.0"},
      {:plug, "~> 1.7"},
      {:bcrypt_elixir, "~> 2.0"},
      {:pbkdf2_elixir, "~> 1.0"},
      {:guardian, "~> 2.2.4"},
      {:guardian_phoenix, "~> 2.0.1"},
      {:secure_random, "~> 0.5.0"},
      {:bamboo, "~> 1.3"},
      {:bamboo_postmark, "~> 0.6.0"},
      {:calendar, "~> 0.17"},
      {:calendar_translations, "~> 0.0.4"},
      {:timex, "~> 3.6"},
      {:wallaby, "~> 0.28.0", [runtime: false, only: :test]},
      {:ex_machina, "~> 2.3", only: :test},
      {:sentry, "~> 7.1"},
      {:arc, "~> 0.11.0"},
      {:arc_ecto, "~> 0.11.3"},
      # Used by arc
      {:hackney, "~> 1.9", override: true},
      # Used by arc
      {:ex_aws, "~> 2.0"},
      # Used by arc
      {:ex_aws_s3, "~> 2.0"},
      # Used by arc
      {:poison, "~> 3.1"},
      # Used by arc
      {:sweet_xml, "~> 0.6"},
      {:html_sanitize_ex, "~> 1.1"},
      {:crutches, git: "https://github.com/mykewould/crutches.git"},
      # Pagination
      {:scrivener_ecto, "~> 2.7.0"},
      {:mock, "~> 0.3.3", only: :test},
      {:stripity_stripe, "~> 2.8.0"},
      {:recaptcha, "~> 3.0"},
      {:remote_ip, "~> 0.2.0"},
      {:zarex, "~> 1.0"}
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
      test: [
        "assets.compile --quiet",
        "ecto.create --quiet",
        "ecto.migrate",
        "test"
      ],
      "assets.compile": &compile_assets/1
    ]
  end

  defp compile_assets(_) do
    Mix.shell().cmd("cd assets && node_modules/webpack/bin/webpack.js --mode production")
  end
end
