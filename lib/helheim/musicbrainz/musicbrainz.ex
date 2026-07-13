defmodule Helheim.Musicbrainz do
  @moduledoc """
  Shared MusicBrainz settings. The pause is inserted after every API call
  by the enrichment workers, which run on a concurrency-1 queue - together
  that keeps us within MusicBrainz's 1 request/second policy on a single
  node deployment.
  """

  def pause_ms do
    Application.get_env(:helheim, :musicbrainz)[:pause_ms] || 1100
  end
end
