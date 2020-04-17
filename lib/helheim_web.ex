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
      use Phoenix.Controller, namespace: HelheimWeb

      import Plug.Conn
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Guardian.Plug, only: [current_resource: 1]

      import Phoenix.LiveView.Controller

      import HelheimWeb.Router.Helpers
      import HelheimWeb.Gettext
      import HelheimWeb.PaginationSanitization
      import HelheimWeb.ScrubGetParams, only: [scrub_get_params: 2]

      alias Helheim.Repo
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/helheim_web/templates",
                        namespace: HelheimWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Guardian.Plug, only: [current_resource: 1]

      import Phoenix.LiveView.Helpers

      # TODO: Remove
      # https://gist.github.com/chrismccord/bb1f8b136f5a9e4abc0bfc07b832257e#add-a-routes-alias-and-update-your-router-calls
      import HelheimWeb.Router.Helpers
      import HelheimWeb.ErrorHelpers
      import HelheimWeb.Gettext
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
      import HelheimWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
