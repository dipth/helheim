defmodule Helheim.Musicbrainz do
  @moduledoc """
  Cluster-wide pacing for MusicBrainz API calls. MusicBrainz allows one
  request per second per IP; the app runs on multiple machines behind one
  egress, so per-process sleeping is not enough. `paced/1` serializes the
  call plus a cooldown across ALL nodes via a Postgres advisory lock: only
  one MusicBrainz request can be in flight (or cooling down) at any time,
  no matter how many machines run the enrichment queue.
  """

  alias Helheim.Repo

  # Arbitrary but stable application-wide lock id for MusicBrainz pacing.
  @advisory_lock_key 727_274_269

  def paced(fun) do
    {:ok, result} =
      Repo.transaction(
        fn ->
          Ecto.Adapters.SQL.query!(Repo, "SELECT pg_advisory_xact_lock($1)", [@advisory_lock_key])
          result = fun.()
          Process.sleep(pause_ms())
          result
        end,
        timeout: :infinity
      )

    result
  end

  def pause_ms do
    Application.get_env(:helheim, :musicbrainz)[:pause_ms] || 1100
  end
end
