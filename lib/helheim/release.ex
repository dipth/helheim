defmodule Helheim.Release do
  @moduledoc """
  Release tasks that can be invoked via the release binary's `eval` command,
  since Mix is not available in production releases.

  ## Examples

      # Run all pending migrations
      /app/bin/helheim eval "Helheim.Release.migrate()"

      # Roll back to a specific migration version
      /app/bin/helheim eval "Helheim.Release.rollback(Helheim.Repo, 20230101120000)"
  """

  @app :helheim

  @doc """
  Runs all pending Ecto migrations for every repo configured under `:ecto_repos`.
  """
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Rolls back the given `repo` to the specified migration `version`.

  ## Parameters

    - `repo` - The Ecto repo module, e.g. `Helheim.Repo`.
    - `version` - The migration version (integer timestamp) to roll back to.

  ## Example

      Helheim.Release.rollback(Helheim.Repo, 20230101120000)
  """
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(:ssl)
    Application.load(@app)
  end
end
