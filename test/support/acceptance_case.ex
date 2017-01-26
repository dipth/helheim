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
      import Altnation.Gettext
      import Altnation.Factory

      defp sign_in(session, user) do
        session
        |> visit("/sessions/new")
        |> fill_in(gettext("E-mail"), with: user.email)
        |> fill_in(gettext("Password"), with: "password")
        |> click_on(gettext("Sign In"))
      end

      defp create_and_sign_in_user(context) do
        user = insert(:user)
        context[:session] |> sign_in(user)
        [user: user]
      end
    end
  end

  setup tags do
    Gettext.put_locale(Altnation.Gettext, "da")

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Altnation.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Altnation.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Altnation.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    session = Wallaby.Session.set_window_size(session, 1366, 768)
    {:ok, session: session}
  end
end
