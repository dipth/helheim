defmodule Mix.Tasks.Helheim.EnrichBackfill do
  @moduledoc "Enqueues metadata enrichment jobs for all unenriched songs."
  @shortdoc "Backfills song metadata enrichment"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    count = Helheim.Music.Enrichment.backfill()
    Mix.shell().info("Enqueued enrichment for #{count} songs")
  end
end
