defmodule StyleguideWeb.Router do
  use StyleguideWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StyleguideWeb do
    get "/health", HealthController, :index
  end

  # Authentik OIDC (same paths as hologram-start-app)
  scope "/auth", StyleguideWeb do
    pipe_through :browser

    get "/oidc", SSOController, :oidc_init
    get "/oidc/callback", SSOController, :oidc_callback
    get "/logout", SSOController, :logout
  end
end
