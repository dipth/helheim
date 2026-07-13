defmodule Helheim.NamedLookup do
  @moduledoc """
  Shared case-insensitive find-or-create for schemas whose identity is a
  `lower(name)` unique index (artists, tags).

  The insert uses ON CONFLICT DO UPDATE with RETURNING rather than DO
  NOTHING, so the existing row always comes back with its id - both under
  concurrent inserts and when Elixir's String.downcase and Postgres'
  lower() disagree about the casefolding of a name (in which case the
  Elixir-side lookup misses but the index still conflicts).
  """

  import Ecto.Query
  alias Helheim.Repo

  def get_or_create!(schema, name) do
    get(schema, name) ||
      schema
      |> struct()
      |> schema.changeset(%{name: name})
      |> Repo.insert!(
        on_conflict: {:replace, [:updated_at]},
        conflict_target: {:unsafe_fragment, "(lower(name))"},
        returning: true
      )
  end

  def get(schema, name) do
    Repo.one(from r in schema, where: fragment("lower(?)", r.name) == ^String.downcase(name))
  end
end
