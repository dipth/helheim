defmodule Helheim.MixProject do
  use Mix.Project

  def project do
    [
      app: :helheim,
      version: "0.0.2",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        helheim: [
          include_executables_for: [:unix]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Helheim.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
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
      {:phoenix, "~> 1.8.5"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_poller, "~> 1.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:ecto_sql, "~> 3.12"},
      {:phoenix_ecto, "~> 4.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:gettext, "~> 0.26"},
      {:bandit, "~> 1.6"},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},
      {:bcrypt_elixir, "~> 3.0"},
      {:pbkdf2_elixir, "~> 2.0"},
      {:guardian, "~> 2.3"},
      {:guardian_phoenix, "~> 2.0"},
      {:bamboo, "~> 2.5"},
      {:bamboo_phoenix, "~> 1.0"},
      {:bamboo_postmark, "~> 1.0"},
      {:calendar, "~> 0.18"},
      {:calendar_translations, "~> 0.0.4"},
      {:timex, "~> 3.7"},
      {:wallaby, "~> 0.30", [runtime: false, only: :test]},
      {:ex_machina, "~> 2.8", only: :test},
      {:sentry, "~> 10.0"},
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.12"},
      {:hackney, "~> 1.18", override: true},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.6"},
      {:html_sanitize_ex, "~> 1.4"},
      {:scrivener_ecto, "~> 3.0"},
      {:mock, "~> 0.3", only: :test},
      {:stripity_stripe, "~> 3.2"},
      {:req, "~> 0.5"},
      {:remote_ip, "~> 1.2"},
      {:zarex, "~> 1.0"},
      {:dns_cluster, "~> 0.2"}
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
    Mix.shell().cmd(
      "cd assets && NODE_OPTIONS=--openssl-legacy-provider node_modules/webpack/bin/webpack.js --mode production"
    )
  end
end
