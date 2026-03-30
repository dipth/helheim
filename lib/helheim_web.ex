defmodule HelheimWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use HelheimWeb, :controller
      use HelheimWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, formats: [html: "View", json: "View", js: "View"]

      import Plug.Conn
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Guardian.Plug, only: [current_resource: 1]

      import HelheimWeb.Router.Helpers
      use Gettext, backend: HelheimWeb.Gettext
      import HelheimWeb.PaginationSanitization
      import HelheimWeb.ScrubGetParams, only: [scrub_get_params: 2]

      alias Helheim.Repo
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/helheim_web/templates",
        namespace: HelheimWeb

      import Phoenix.Controller, only: [view_module: 1]

      defp get_flash(conn, key), do: Phoenix.Flash.get(conn.assigns.flash, key)

      import Phoenix.HTML
      use PhoenixHTMLHelpers

      import Guardian.Plug, only: [current_resource: 1]

      import Phoenix.Component, except: [link: 1]

      import HelheimWeb.Router.Helpers
      import HelheimWeb.ErrorHelpers
      use Gettext, backend: HelheimWeb.Gettext
      import HelheimWeb.TimeHelpers
      import HelheimWeb.PaginationHelpers
      import HelheimWeb.ProfileHelpers
      import HelheimWeb.VisitorLogEntryHelpers
      import HelheimWeb.NotificationHelpers
      import HelheimWeb.CommentHelpers
      import HelheimWeb.VisibilityHelpers
      import HelheimWeb.TableHelpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: HelheimWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
