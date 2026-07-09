defmodule Helheim.Lastfm.SchedulerWorker do
  @moduledoc """
  Cron triggered worker that enqueues one PollWorker job per working Last.fm
  connection, staggered over the following minutes to spread out the API
  calls.
  """

  use Oban.Worker, queue: :lastfm, max_attempts: 1

  import Ecto.Query
  alias Helheim.Repo
  alias Helheim.LastfmAccount
  alias Helheim.Lastfm.PollWorker

  @stagger_window_in_seconds 240

  @impl Oban.Worker
  def perform(_job) do
    LastfmAccount
    |> LastfmAccount.not_broken()
    |> select([a], a.id)
    |> Repo.all()
    |> Enum.with_index()
    |> Enum.each(fn {lastfm_account_id, index} ->
      %{lastfm_account_id: lastfm_account_id}
      |> PollWorker.new(schedule_in: rem(index, @stagger_window_in_seconds))
      |> Oban.insert!()
    end)

    :ok
  end
end
