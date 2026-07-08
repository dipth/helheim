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
      use Gettext, backend: HelheimWeb.Gettext
      import Helheim.Factory

      defp sign_in(session, user) do
        session
        |> visit("/sessions/new")
        |> fill_in(Wallaby.Query.text_field(gettext("E-mail")), with: user.email)
        |> fill_in(Wallaby.Query.text_field(gettext("Password")), with: "password")
        |> click(Wallaby.Query.button(gettext("Sign In")))
        # Wait for the post-login redirect to finish so subsequent navigation
        # doesn't race the sign-in request
        |> assert_has(Wallaby.Query.css(".alert.alert-success"))
      end

      defp create_and_sign_in_user(context) do
        user = insert(:user)
        context[:session] |> sign_in(user)
        [user: user]
      end
    end
  end

  setup tags do
    Gettext.put_locale("da")

    owner =
      Ecto.Adapters.SQL.Sandbox.start_owner!(
        Helheim.Repo,
        shared: not tags[:async],
        ownership_timeout: 60000
      )

    on_exit(fn ->
      # Let in-flight browser requests (e.g. XHRs fired on page load) finish
      # before tearing down the sandbox owner. Otherwise they crash the shared
      # connection and can poison the next test's database access.
      Process.sleep(200)
      Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
    end)

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Helheim.Repo, owner)
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    session = Wallaby.Browser.resize_window(session, 1366, 768)
    {:ok, session: session}
  end
end
