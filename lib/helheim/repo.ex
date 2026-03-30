defmodule Helheim.Repo do
  use Ecto.Repo, otp_app: :helheim, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 25

  @doc """
  Dynamically loads the repository url from the DATABASE_URL environment
  variable if present, otherwise falls back to whatever is configured
  via config files (e.g. NEON_URL in runtime.exs).
  """
  def init(_, opts) do
    case System.get_env("DATABASE_URL") do
      nil -> {:ok, opts}
      url -> {:ok, Keyword.put(opts, :url, url)}
    end
  end
end
