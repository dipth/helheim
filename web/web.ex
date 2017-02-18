defmodule Helheim.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Helheim.Web, :controller
      use Helheim.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema
      use Calecto.Schema, usec: true

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      use Helheim.TrimFieldsConcern
      use Helheim.AllowCustomValueForFieldsConcern
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias Helheim.Repo
      import Ecto
      import Ecto.Query

      import Guardian.Plug, only: [current_resource: 1]

      import Helheim.Router.Helpers
      import Helheim.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Guardian.Plug, only: [current_resource: 1]

      import Helheim.Router.Helpers
      import Helheim.ErrorHelpers
      import Helheim.Gettext
      import Helheim.TimeHelpers
      import Helheim.PaginationHelpers

      use Helheim.BreadcrumbsDefaults
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Helheim.Repo
      import Ecto
      import Ecto.Query
      import Helheim.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
