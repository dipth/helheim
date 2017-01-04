defmodule Altnation.AcceptanceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias Altnation.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Altnation.Router.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Altnation.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Altnation.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Altnation.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
