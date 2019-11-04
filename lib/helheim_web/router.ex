defmodule HelheimWeb.Router do
  use HelheimWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HelheimWeb.Locale
  end

  pipeline :auth do
    plug HelheimWeb.Auth.Pipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
    plug HelheimWeb.Plug.TrackLogin
    plug HelheimWeb.Plug.LoadNotifications
    plug HelheimWeb.Plug.LoadUnreadPrivateConversations
    plug HelheimWeb.Plug.LoadPendingFriendships
    plug HelheimWeb.Plug.EnforceBan
    plug HelheimWeb.Plug.LoadPendingCalendarEvents
  end

  pipeline :ensure_admin do
    plug HelheimWeb.Plug.VerifyAdmin
  end

  pipeline :ensure_mod do
    plug HelheimWeb.Plug.VerifyMod
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelheimWeb do
    pipe_through [:browser] # Use the default browser stack

    resources "/sessions", SessionController, only: [:new, :create]
  end

  scope "/", HelheimWeb do
    pipe_through [:browser, :auth] # Use the default browser stack

    get "/", PageController, :index
    get "/terms", PageController, :terms
    get "/confirmation_pending", PageController, :confirmation_pending
    get "/debug", PageController, :debug
    resources "/registrations", RegistrationController, only: [:new, :create]
    resources "/confirmations", ConfirmationController, only: [:new, :create, :show]
    resources "/password_resets", PasswordResetController, only: [:new, :create, :show, :update]
  end

  scope "/", HelheimWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    get "/banned", PageController, :banned
    get "/help/verification", HelpController, :verification
    get "/signed_in", PageController, :signed_in
    get "/front_page", PageController, :front_page
    get "/staff", PageController, :staff
    get "/sessions/sign_out", SessionController, :delete
    resources "/account", AccountController, singleton: true, only: [:edit, :update, :delete]
    resources "/preferences", PreferenceController, singleton: true, only: [:edit, :update]
    resources "/profile", ProfileController, singleton: true, only: [:show, :edit, :update]
    resources "/profiles", ProfileController, only: [:index, :show], as: :public_profile do
      resources "/blog_posts", BlogPostController, only: [:index, :show] do
        resources "/visitor_log_entries", VisitorLogEntryController, only: [:index]
      end
      resources "/comments", CommentController, only: [:index, :create, :edit, :update]
      resources "/photo_albums", PhotoAlbumController, only: [:index, :show] do
        resources "/photos", PhotoController, only: [:show] do
          resources "/visitor_log_entries", VisitorLogEntryController, only: [:index]
        end
        resources "/visitor_log_entries", VisitorLogEntryController, only: [:index]
      end
      resources "/visitor_log_entries", VisitorLogEntryController, only: [:index]
      resources "/notification_subscription", NotificationSubscriptionController, singleton: true, only: [:update]
      resources "/block", BlockController, singleton: true, only: [:create, :delete, :show]
      resources "/contact_request", FriendshipRequestController, singleton: true, only: [:create, :delete]
      resources "/contact", FriendshipController, singleton: true, only: [:create, :delete]
      resources "/contacts", FriendshipController, only: [:index]
    end
    resources "/blog_posts", BlogPostController, only: [:index, :new, :create, :edit, :update, :delete] do
      resources "/comments", CommentController, only: [:create, :edit, :update]
      resources "/notification_subscription", NotificationSubscriptionController, singleton: true, only: [:update]
    end
    resources "/photo_albums", PhotoAlbumController, only: [:new, :create, :edit, :update, :delete] do
      resources "/photos", PhotoController, only: [:create, :edit, :update, :delete] do
        resources "/comments", CommentController, only: [:create, :edit, :update]
        resources "/notification_subscription", NotificationSubscriptionController, singleton: true, only: [:update]
      end
      resources "/photo_positions", PhotoPositionController, singleton: true, only: [:update], as: :photo_positions
    end
    resources "/photos", PhotoController, only: [:index]
    resources "/private_conversations", PrivateConversationController, param: "partner_id", only: [:index, :show, :delete] do
      resources "/messages", PrivateMessageController, only: [:create], as: :message
    end
    resources "/forums", ForumController, only: [:index, :show] do
      resources "/forum_topics", ForumTopicController, only: [:new, :create, :show, :edit, :update] do
        resources "/forum_replies", ForumReplyController, only: [:create, :edit, :update]
      end
    end
    resources "/forum_topics", ForumTopicController, only: [] do
      resources "/notification_subscription", NotificationSubscriptionController, singleton: true, only: [:update]
    end
    resources "/notifications", NotificationController, only: [:show]
    resources "/navbar", NavbarController, singleton: true, only: [:show]
    resources "/usernames", UsernameController, only: [:index, :show]
    resources "/blocks", BlockController, only: [:index]
    resources "/comments", CommentController, only: [:delete]
    resources "/donations", DonationController, only: [:new, :create]
    get "/donations/thank_you", DonationController, :thank_you
    resources "/contacts", FriendshipController, only: [:index]
    resources "/calendar_events", CalendarEventController do
      resources "/comments", CommentController, only: [:create, :edit, :update]
      resources "/notification_subscription", NotificationSubscriptionController, singleton: true, only: [:update]
    end
    resources "/online_users", OnlineUserController, only: [:index]
  end

  scope "/mod", HelheimWeb.Mod, as: :mod do
    pipe_through [:browser, :auth, :ensure_auth, :ensure_mod]

    resources "/calendar_events", CalendarEventController, only: [:index, :show, :update, :delete]
  end

  scope "/admin", HelheimWeb.Admin, as: :admin do
    pipe_through [:browser, :auth, :ensure_auth, :ensure_admin]

    resources "/forum_categories", ForumCategoryController, only: [:index, :new, :create, :edit, :update, :delete] do
      resources "/forums", ForumController, only: [:new, :create, :edit, :update, :delete]
    end
    resources "/terms", TermController
    resources "/users", UserController, only: [:index, :show, :edit, :update] do
      resources "/verification", User.VerificationController, singleton: true, only: [:create, :delete]
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
