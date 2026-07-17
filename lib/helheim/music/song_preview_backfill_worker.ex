defmodule Helheim.Music.SongPreviewBackfillWorker do
  @moduledoc """
  Backfills the Deezer id (and thereby the 30 second preview) for songs
  that were enriched before previews existed - a single Deezer lookup,
  without re-running the full Last.fm/MusicBrainz enrichment. A genuine
  miss just leaves the song without a preview; because a miss is
  indistinguishable from never-checked, re-running the backfill retries
  misses, which is fine for a cheap one-off admin task.
  """

  use Oban.Worker,
    queue: :enrichment,
    # Deprioritized below regular enrichment (default priority 0) so a
    # catalog-wide backfill cannot starve newly scrobbled songs on the
    # concurrency-1 queue.
    priority: 3,
    max_attempts: 5,
    unique: [
      period: 3600,
      keys: [:song_id],
      states: [:available, :scheduled, :executing, :retryable, :suspended]
    ]

  require Logger
  alias Helheim.Repo
  alias Helheim.Song
  alias Helheim.Deezer

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"song_id" => song_id}} = job) do
    song = Repo.get(Song, song_id)

    cond do
      is_nil(song) -> :ok
      song.deezer_id -> :ok
      true -> song |> lookup() |> settle_final_attempt(job, song)
    end
  end

  defp lookup(song) do
    case Deezer.Client.search_track(song.artist_name, song.title) do
      {:ok, %{deezer_id: deezer_id}} ->
        {:ok, _} = song |> Song.changeset(%{deezer_id: deezer_id}) |> Repo.update()
        :ok

      {:error, :not_found} ->
        :ok

      {:error, :rate_limited} ->
        {:snooze, 60}

      error ->
        error
    end
  end

  # Unlike enrichment there is no flag to stamp: a job that still errors
  # on its last attempt is simply logged and given up on - the next
  # backfill run picks the song up again.
  defp settle_final_attempt({:error, reason}, %Oban.Job{attempt: attempt, max_attempts: max}, song) when attempt >= max do
    Logger.error("Preview backfill settled with error for song #{song.id}: #{inspect(reason)}")
    :ok
  end
  defp settle_final_attempt(result, _job, _song), do: result
end
