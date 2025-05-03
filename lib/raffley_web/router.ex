defmodule RaffleyWeb.Router do
  use RaffleyWeb, :router

  import RaffleyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RaffleyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RaffleyWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/survey/:token", PageController, :survey
    get "/survey", PageController, :survey
  end

  # Other scopes may use custom stacks.
  # scope "/api", RaffleyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:raffley, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    # Pipeline with CSRF for dashboard
    pipeline :dev_tools_protected do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {RaffleyWeb.Layouts, :root}
      plug :protect_from_forgery
      plug :put_secure_browser_headers
    end

    # Simple pipeline for mailbox (no CSRF)
    pipeline :dev_tools do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {RaffleyWeb.Layouts, :root}
      plug :put_secure_browser_headers
    end

    scope "/dev" do
      pipe_through :dev_tools_protected
      live_dashboard "/dashboard", metrics: RaffleyWeb.Telemetry
    end

    scope "/dev" do
      pipe_through :dev_tools
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  pipeline :require_admin do
    plug :require_authenticated_user
    plug :ensure_admin
  end

  pipeline :require_super_admin do
    plug :require_authenticated_user
    plug :ensure_super_admin
  end

  # Regular admin routes (accessible by both admins and super admins)
  scope "/admin", RaffleyWeb do
    pipe_through [:browser, :require_admin]

    get "/", AdminController, :index

    live_session :require_admin_user,
      on_mount: [{RaffleyWeb.UserAuth, :ensure_admin}] do
      # Regular admin routes go here
      # Add other admin routes here that should be accessible to all admins
    end
  end

  # Redirect old user management URL to new one
  scope "/admin", RaffleyWeb do
    pipe_through [:browser, :require_super_admin]
    
    get "/users", AdminController, :redirect_to_user_management
  end

  # Super Admin routes (only accessible by super admins)
  scope "/admin/super", RaffleyWeb do
    pipe_through [:browser, :require_super_admin]

    live_session :require_super_admin_user,
      on_mount: [{RaffleyWeb.UserAuth, :ensure_super_admin}] do
      live "/users", AdminLive.UserManagement, :index
      live "/users/:id", AdminLive.UserManagement, :edit
    end
  end

  ## Authentication routes

  scope "/", RaffleyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RaffleyWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end
  end

  scope "/", RaffleyWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{RaffleyWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
