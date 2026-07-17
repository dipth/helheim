defmodule Helheim.Music.SongPreviewBackfillWorkerTest do
  use Helheim.DataCase
  use Oban.Testing, repo: Helheim.Repo
  import Mock
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.Deezer
  alias Helheim.Music.SongPreviewBackfillWorker

  defp insert_enriched_song_without_preview(attrs \\ []) do
    insert(:song, Keyword.merge([enriched_at: DateTime.utc_now(), deezer_id: nil], attrs))
  end

  describe "perform/1" do
    test "stores the deezer id without touching the rest of the enrichment" do
      song = insert_enriched_song_without_preview(release_year: 1986)

      with_mock Deezer.Client, [:passthrough], [search_track: fn "Metallica", _title -> {:ok, %{deezer_id: 424_565_222}} end] do
        assert :ok = perform_job(SongPreviewBackfillWorker, %{song_id: song.id})
      end

      song = Repo.get(Song, song.id)
      assert song.deezer_id == 424_565_222
      assert song.release_year == 1986
    end

    test "leaves the song alone when deezer has no match" do
      song = insert_enriched_song_without_preview()

      with_mock Deezer.Client, [:passthrough], [search_track: fn _a, _t -> {:error, :not_found} end] do
        assert :ok = perform_job(SongPreviewBackfillWorker, %{song_id: song.id})
      end

      assert Repo.get(Song, song.id).deezer_id == nil
    end

    test "skips songs that already have a deezer id" do
      song = insert_enriched_song_without_preview(deezer_id: 111)

      with_mock Deezer.Client, [:passthrough], [search_track: fn _a, _t -> {:ok, %{deezer_id: 222}} end] do
        assert :ok = perform_job(SongPreviewBackfillWorker, %{song_id: song.id})
        assert not called Deezer.Client.search_track(:_, :_)
      end

      assert Repo.get(Song, song.id).deezer_id == 111
    end

    test "skips songs that no longer exist" do
      assert :ok = perform_job(SongPreviewBackfillWorker, %{song_id: 1_234_567})
    end

    test "snoozes when deezer rate limits" do
      song = insert_enriched_song_without_preview()

      with_mock Deezer.Client, [:passthrough], [search_track: fn _a, _t -> {:error, :rate_limited} end] do
        assert {:snooze, 60} = perform_job(SongPreviewBackfillWorker, %{song_id: song.id})
      end
    end

    test "retries transient errors and gives up quietly on the final attempt" do
      song = insert_enriched_song_without_preview()

      with_mock Deezer.Client, [:passthrough], [search_track: fn _a, _t -> {:error, {:http_error, 500, ""}} end] do
        assert {:error, _} = perform_job(SongPreviewBackfillWorker, %{song_id: song.id}, attempt: 1)
        assert :ok = perform_job(SongPreviewBackfillWorker, %{song_id: song.id}, attempt: 5)
      end

      assert Repo.get(Song, song.id).deezer_id == nil
    end
  end
end
