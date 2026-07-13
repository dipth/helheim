defmodule Helheim.Music.Enrichment do
  @moduledoc """
  Backfill entry point: enqueues an enrichment job for every song that has
  not been enriched yet. Jobs are inserted one by one because Oban's
  insert_all does not apply unique-job constraints; that keeps repeated
  backfill runs idempotent, and speed is irrelevant for this one-off admin
  task. The concurrency-1 enrichment queue then works through the jobs at
  a rate that respects the external APIs.
  """

  import Ecto.Query
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.Music.SongEnrichmentWorker

  def backfill do
    Song
    |> Song.unenriched()
    |> select([s], s.id)
    |> Repo.all()
    |> Enum.map(fn song_id ->
      {:ok, _} = %{song_id: song_id} |> SongEnrichmentWorker.new() |> Oban.insert()
    end)
    |> length()
  end
end
