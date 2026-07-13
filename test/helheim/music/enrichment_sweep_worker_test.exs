defmodule Helheim.Music.EnrichmentSweepWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  alias Helheim.Repo
  alias Helheim.Music.EnrichmentSweepWorker
  alias Helheim.Music.SongEnrichmentWorker

  test "enqueues enrichment for unenriched songs older than an hour" do
    old_unenriched = insert(:song, enriched_at: nil)
    Repo.update_all(Helheim.Song, set: [inserted_at: Timex.shift(Timex.now, hours: -2)])
    fresh_unenriched = insert(:song, enriched_at: nil)
    enriched = insert(:song, enriched_at: DateTime.utc_now())

    assert :ok = perform_job(EnrichmentSweepWorker, %{})

    assert_enqueued worker: SongEnrichmentWorker, args: %{song_id: old_unenriched.id}
    refute_enqueued worker: SongEnrichmentWorker, args: %{song_id: fresh_unenriched.id}
    refute_enqueued worker: SongEnrichmentWorker, args: %{song_id: enriched.id}
  end
end
