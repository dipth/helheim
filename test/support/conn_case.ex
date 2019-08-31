defmodule HelheimWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import HelheimWeb.Router.Helpers
      import HelheimWeb.Gettext
      import Helheim.Factory

      alias Helheim.Repo
      alias Helheim.Auth.Guardian

      # The default endpoint for testing
      @endpoint HelheimWeb.Endpoint

      @default_opts [
        store: :cookie,
        key: "foobar",
        encryption_salt: "encrypted cookie salt",
        signing_salt: "signing salt"
      ]
      @secret String.duplicate("abcdef0123456789", 8)
      @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))

      def conn_with_fetched_session(the_conn) do
        put_in(the_conn.secret_key_base, @secret)
        |> Plug.Session.call(@signing_opts)
        |> Plug.Conn.fetch_session
      end

      def sign_in(conn, resource) do
        conn
        |> conn_with_fetched_session
        |> Guardian.Plug.sign_in(resource)
      end

      defp create_and_sign_in_user(context) do
        user = insert(:user)
        conn = context[:conn]
        conn = conn |> sign_in(user)
        [conn: conn, user: user]
      end

      defp create_and_sign_in_admin(context) do
        admin = insert(:user, role: "admin")
        conn = context[:conn]
        conn = conn |> sign_in(admin)
        [conn: conn, admin: admin]
      end

      defp create_and_sign_in_mod(context) do
        mod = insert(:user, role: "mod")
        conn = context[:conn]
        conn = conn |> sign_in(mod)
        [conn: conn, mod: mod]
      end
    end
  end

  setup tags do
    Gettext.put_locale(HelheimWeb.Gettext, "da")
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Helheim.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Helheim.Repo, {:shared, self()})
    end
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
