defmodule Mix.Tasks.Helheim.PreviewBackfill do
  @moduledoc "Enqueues Deezer preview id lookups for already-enriched songs that have none."
  @shortdoc "Backfills song preview ids from Deezer"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    count = Helheim.Music.Enrichment.backfill_previews()
    Mix.shell().info("Enqueued preview backfill for #{count} songs")
  end
end
