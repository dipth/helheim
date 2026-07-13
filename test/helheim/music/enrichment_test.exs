defmodule Helheim.Music.EnrichmentTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  alias Helheim.Music.Enrichment
  alias Helheim.Music.SongEnrichmentWorker

  describe "backfill/0" do
    test "enqueues enrichment for every unenriched song" do
      song_1 = insert(:song, enriched_at: nil)
      song_2 = insert(:song, enriched_at: nil)
      enriched = insert(:song, enriched_at: DateTime.utc_now())

      assert Enrichment.backfill() == 2

      assert_enqueued worker: SongEnrichmentWorker, args: %{song_id: song_1.id}
      assert_enqueued worker: SongEnrichmentWorker, args: %{song_id: song_2.id}
      refute_enqueued worker: SongEnrichmentWorker, args: %{song_id: enriched.id}
    end

    test "is idempotent thanks to job uniqueness" do
      insert(:song, enriched_at: nil)

      assert Enrichment.backfill() == 1
      assert Enrichment.backfill() == 1
      assert length(all_enqueued(worker: SongEnrichmentWorker)) == 1
    end
  end
end
