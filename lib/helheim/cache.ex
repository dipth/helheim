defmodule Helheim.Cache do
  @moduledoc """
  Minimal ETS backed read-through cache for values that are expensive to
  compute but may be slightly stale, such as the front page music charts.
  """

  use GenServer

  @table __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(nil) do
    :ets.new(@table, [:named_table, :public, read_concurrency: true])
    {:ok, nil}
  end

  @doc """
  Returns the cached value for `key`, or computes it with `fun` and caches
  it for `ttl_ms`. A ttl of 0 (or less) bypasses the cache entirely.
  """
  def fetch(key, ttl_ms, fun) when is_integer(ttl_ms) do
    if ttl_ms > 0 do
      lookup(key, fun, ttl_ms)
    else
      fun.()
    end
  end

  defp lookup(key, fun, ttl_ms) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@table, key) do
      [{^key, value, expires_at}] when expires_at > now ->
        value
      _ ->
        value = fun.()
        :ets.insert(@table, {key, value, now + ttl_ms})
        value
    end
  end
end
