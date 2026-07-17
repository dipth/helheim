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
  alias Helheim.Music.SongPreviewBackfillWorker

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

  @doc """
  Enqueues a preview-only Deezer lookup for every already-enriched song
  still missing its deezer_id - the catalog that predates the preview
  feature. Unenriched songs are skipped: their regular enrichment job
  resolves the deezer_id itself.
  """
  def backfill_previews do
    Song
    |> where([s], not is_nil(s.enriched_at) and is_nil(s.deezer_id))
    |> select([s], s.id)
    |> Repo.all()
    |> Enum.map(fn song_id ->
      {:ok, _} = %{song_id: song_id} |> SongPreviewBackfillWorker.new() |> Oban.insert()
    end)
    |> length()
  end
end
