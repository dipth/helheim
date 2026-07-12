defmodule Helheim.Lastfm.SchedulerWorker do
  @moduledoc """
  Cron triggered worker that enqueues one PollWorker job per working Last.fm
  connection, staggered over the following minutes to spread out the API
  calls.
  """

  use Oban.Worker, queue: :lastfm, max_attempts: 1

  import Ecto.Query
  require Logger
  alias Helheim.Repo
  alias Helheim.LastfmAccount
  alias Helheim.Lastfm.PollWorker

  @stagger_window_in_seconds 240

  @impl Oban.Worker
  def perform(_job) do
    account_ids =
      LastfmAccount
      |> LastfmAccount.not_broken()
      |> select([a], a.id)
      |> Repo.all()

    count = length(account_ids)

    account_ids
    |> Enum.with_index()
    |> Enum.each(fn {lastfm_account_id, index} ->
      # Spread the polls evenly across the window no matter how many
      # accounts there are, and never let one failed insert abort the
      # remaining enqueues.
      schedule_in = div(index * @stagger_window_in_seconds, count)

      %{lastfm_account_id: lastfm_account_id}
      |> PollWorker.new(schedule_in: schedule_in)
      |> Oban.insert()
      |> case do
        {:ok, _job} -> :ok
        {:error, reason} -> Logger.error("Failed to enqueue lastfm poll for account #{lastfm_account_id}: #{inspect(reason)}")
      end
    end)

    :ok
  end
end
