defmodule BeerGameWeb.Router do
  use BeerGameWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BeerGameWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BeerGameWeb do
    pipe_through :browser

    live "/", LandingLive.Index, :index

    live "/session", SessionLive.Index, :index
    live "/session/new", SessionLive.New, :new
    live "/session/:id", SessionLive.Show, :show

    live "/player", PlayerLive.Index, :index
    live "/player/new", PlayerLive.Index, :new
    live "/player/:id", PlayerLive.Show, :show

    live "/board", BoardLive.Index, :index
    live "/board/new", BoardLive.New, :new
    live "/board/:id", BoardLive.Show, :show
    live "/board/:id/player", BoardLive.PlayerSelection, :player_selection
  end

  # Other scopes may use custom stacks.
  # scope "/api", BeerGameWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BeerGameWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
