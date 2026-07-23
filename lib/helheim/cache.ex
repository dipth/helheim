defmodule Helheim.Cache do
  @moduledoc """
  Minimal ETS backed read-through cache for values that are expensive to
  compute but may be slightly stale, such as the front page music charts.

  Keys are tuples whose first element names the cache, e.g.
  `{:top_songs_last_day, 5}` - `invalidate/1` drops every entry sharing
  that first element. The cache is node-local: in a multi-node deployment
  each node caches (and invalidates) independently, so cross-node
  staleness is bounded only by the entry's ttl.
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
  it for `ttl_ms`. A ttl of 0 (or less) bypasses the cache entirely. The
  optional `:cache_if` predicate decides whether a computed value is worth
  caching - e.g. to avoid pinning transient API errors for the whole ttl.
  """
  def fetch(key, ttl_ms, fun, opts \\ []) when is_integer(ttl_ms) do
    if ttl_ms > 0 do
      lookup(key, fun, ttl_ms, Keyword.get(opts, :cache_if, fn _value -> true end))
    else
      fun.()
    end
  end

  @doc """
  Removes all cached entries whose key is a tuple starting with `prefix`,
  e.g. `invalidate(:top_songs_last_day)` drops the entry for every count.
  Also bumps the prefix's generation so a computation already in flight
  when the invalidation happened cannot re-insert its (stale) result.
  """
  def invalidate(prefix) do
    :ets.update_counter(@table, {:generation, prefix}, 1, {{:generation, prefix}, 0})
    :ets.match_delete(@table, {{prefix, :_}, :_, :_})
    :ok
  end

  defp lookup(key, fun, ttl_ms, cache_if) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@table, key) do
      [{^key, value, expires_at}] when expires_at > now ->
        value
      _ ->
        generation = generation(key)
        value = fun.()

        if cache_if.(value) and generation(key) == generation do
          :ets.insert(@table, {key, value, now + ttl_ms})
        end

        value
    end
  end

  defp generation(key) do
    case :ets.lookup(@table, {:generation, cache_prefix(key)}) do
      [{_key, generation}] -> generation
      [] -> 0
    end
  end

  defp cache_prefix(key) when is_tuple(key), do: elem(key, 0)
  defp cache_prefix(key), do: key
end
