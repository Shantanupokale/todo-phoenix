defmodule TodoBuddyWeb.Router do
  use TodoBuddyWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {TodoBuddyWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :require_auth do
    plug TodoBuddyWeb.Plugs.Auth, :require_auth
  end

  pipeline :redirect_if_authenticated do
    plug TodoBuddyWeb.Plugs.Auth, :redirect_if_authenticated
  end


    # public pages (but redirect logged-in users away from login/register)
  scope "/", TodoBuddyWeb do
    pipe_through [:browser, :redirect_if_authenticated]
    live "/login", LoginLive
    live "/register", RegisterLive
  end

  # public pages
  scope "/", TodoBuddyWeb do
    pipe_through :browser
    live "/", LandingLive
    get "/auth/callback", AuthController, :callback
    get "/auth/logout", AuthController, :logout
  end

  # protected pages
  scope "/", TodoBuddyWeb do
    pipe_through [:browser, :require_auth]
    live "/dashboard", DashboardLive
  end


  # scope "/", TodoBuddyWeb do
  #   pipe_through(:browser)

  #   live("/", LandingLive)
  #   live("/login", LoginLive)
  #   live("/register", RegisterLive)
  #   live("/dashboard", DashboardLive)

  #   get("/auth/callback", AuthController, :callback)
  #   get("/auth/logout", AuthController, :logout)
  # end



  # Other scopes may use custom stacks.
  # scope "/api", TodoBuddyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:todo_buddy, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TodoBuddyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
