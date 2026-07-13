defmodule Helheim.Music.EnrichmentSweepWorker do
  @moduledoc """
  Hourly safety net for the enrichment pipeline: enqueues jobs for songs
  that are still unenriched. Covers songs whose post-poll enqueue was lost
  (crash between commit and enqueue) and retries songs whose earlier
  enrichment attempts were exhausted. Songs younger than an hour are left
  to the regular poll trigger.
  """

  use Oban.Worker, queue: :enrichment, max_attempts: 1

  import Ecto.Query
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.Music.SongEnrichmentWorker

  @batch_limit 500

  @impl Oban.Worker
  def perform(_job) do
    cutoff = DateTime.add(DateTime.utc_now(), -3600, :second)

    Song
    |> Song.unenriched()
    |> where([s], s.inserted_at < ^cutoff)
    |> order_by([s], asc: s.id)
    |> limit(@batch_limit)
    |> select([s], s.id)
    |> Repo.all()
    |> Enum.each(fn song_id ->
      %{song_id: song_id}
      |> SongEnrichmentWorker.new()
      |> Oban.insert()
    end)

    :ok
  end
end
