defmodule Helheim.Router do
  use Helheim.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.VerifyRememberMe
    plug Guardian.Plug.LoadResource
    plug Helheim.Locale
  end

  pipeline :browser_auth do
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.VerifyRememberMe
    plug Guardian.Plug.EnsureAuthenticated, handler: Helheim.Token
    plug Guardian.Plug.LoadResource
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Helheim do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/confirmation_pending", PageController, :confirmation_pending
    get "/debug", PageController, :debug
    resources "/registrations", RegistrationController, only: [:new, :create]
    resources "/confirmations", ConfirmationController, only: [:new, :create, :show]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/password_resets", PasswordResetController, only: [:new, :create, :show, :update]
  end

  scope "/", Helheim do
    pipe_through [:browser, :browser_auth]

    get "/signed_in", PageController, :signed_in
    get "/front_page", PageController, :front_page
    resources "/account", AccountController, singleton: true, only: [:edit, :update]
    resources "/profile", ProfileController, singleton: true, only: [:show, :edit, :update]
    resources "/profiles", ProfileController, only: [:show], as: :public_profile do
      resources "/blog_posts", BlogPostController, only: [:index, :show]
      resources "/comments", ProfileCommentController, only: [:index, :create], as: :comment
    end
    resources "/blog_posts", BlogPostController, only: [:new, :create, :edit, :update, :delete] do
      resources "/comments", BlogPostCommentController, only: [:create], as: :comment
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", Helheim do
  #   pipe_through :api
  # end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
