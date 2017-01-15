defmodule Altnation.Router do
  use Altnation.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Altnation.Locale
  end

  pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.EnsureAuthenticated, handler: Altnation.Token
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Altnation do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/confirmation_pending", PageController, :confirmation_pending
    get "/debug", PageController, :debug
    resources "/registrations", RegistrationController, only: [:new, :create]
    resources "/confirmations", ConfirmationController, only: [:new, :create, :show]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/password_resets", PasswordResetController, only: [:new, :create, :show, :update]
  end

  scope "/", Altnation do
    pipe_through [:browser, :browser_auth]

    get "/signed_in", PageController, :signed_in
    get "/front_page", PageController, :front_page
  end

  # Other scopes may use custom stacks.
  # scope "/api", Altnation do
  #   pipe_through :api
  # end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
