defmodule Helheim.Spotify.SchedulerWorker do
  @moduledoc """
  Cron triggered worker that enqueues one PollWorker job per working Spotify
  connection, staggered over the following minutes to spread out the API
  calls.
  """

  use Oban.Worker, queue: :spotify, max_attempts: 1

  import Ecto.Query
  alias Helheim.Repo
  alias Helheim.SpotifyAccount
  alias Helheim.Spotify.PollWorker

  @stagger_window_in_seconds 240

  @impl Oban.Worker
  def perform(_job) do
    SpotifyAccount
    |> SpotifyAccount.not_broken()
    |> select([a], a.id)
    |> Repo.all()
    |> Enum.with_index()
    |> Enum.each(fn {spotify_account_id, index} ->
      %{spotify_account_id: spotify_account_id}
      |> PollWorker.new(schedule_in: rem(index, @stagger_window_in_seconds))
      |> Oban.insert!()
    end)

    :ok
  end
end
