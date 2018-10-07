defmodule HelheimWeb.AcceptanceCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias Helheim.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import HelheimWeb.Router.Helpers
      import HelheimWeb.Gettext
      import Helheim.Factory

      defp sign_in(session, user) do
        session
        |> visit("/sessions/new")
        |> fill_in(Wallaby.Query.text_field(gettext("E-mail")), with: user.email)
        |> fill_in(Wallaby.Query.text_field(gettext("Password")), with: "password")
        |> click(Wallaby.Query.button(gettext("Sign In")))
      end

      defp create_and_sign_in_user(context) do
        user = insert(:user)
        context[:session] |> sign_in(user)
        [user: user]
      end
    end
  end

  setup tags do
    Gettext.put_locale(HelheimWeb.Gettext, "da")

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Helheim.Repo, ownership_timeout: 60000)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Helheim.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Helheim.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    session = Wallaby.Browser.resize_window(session, 1366, 768)
    {:ok, session: session}
  end
end
