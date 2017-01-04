defmodule Altnation.Router do
  use Altnation.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Altnation do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/confirmation_pending", PageController, :confirmation_pending
    get "/debug", PageController, :debug
    resources "/registrations", RegistrationController
    resources "/confirmations", ConfirmationController
  end

  # Other scopes may use custom stacks.
  # scope "/api", Altnation do
  #   pipe_through :api
  # end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
