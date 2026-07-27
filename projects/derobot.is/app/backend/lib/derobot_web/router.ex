defmodule DerobotWeb.Router do
  use DerobotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug DerobotWeb.AuthPipeline
  end

  pipeline :sso_session do
    # max_age was 300 and is now 900.
    #
    # This cookie used to be dead weight for OIDC: the flow generated no state
    # and no nonce, so nothing depended on the cookie surviving the round trip.
    # It now carries both, which makes the expiry load-bearing for the first
    # time -- and 300 seconds is not long enough for a real sign-in. A password
    # plus a 2FA code typed from a phone routinely exceeds five minutes, and
    # that user would land on an opaque `state_mismatch` for doing nothing
    # wrong. Shipping the state check on a 300s window would have swapped a
    # security hole for an availability bug.
    #
    # Widening is one-directional and safe: a longer window cannot break a flow
    # that already completed inside a shorter one. The cookie holds flow state
    # (state, nonce, redirect target) and never a credential, so this is not a
    # credential-lifetime decision.
    plug Plug.Session,
      store: :cookie,
      key: "_derobot_sso",
      signing_salt: "sso_session_salt",
      same_site: "Lax",
      max_age: 900

    plug :fetch_session
  end

  scope "/", DerobotWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  scope "/api/v1", DerobotWeb do
    pipe_through :api
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
    get "/auth/sso/providers", SSOController, :providers
    post "/auth/sso/exchange", SSOController, :exchange
  end

  scope "/api/v1", DerobotWeb do
    pipe_through [:api, :authenticated]
    get "/auth/me", AuthController, :me
  end

  # SAML 2.0
  if Application.compile_env(:derobot, :saml_enabled) do
    scope "/sso/saml" do
      pipe_through [:sso_session]
      forward "/", Samly.Router
    end
  end

  # OIDC redirect flow
  scope "/auth/oidc", DerobotWeb do
    pipe_through [:sso_session]
    get "/", SSOController, :oidc_init
    get "/callback", SSOController, :oidc_callback
  end

  # Social OAuth (ueberauth handles request + callback)
  scope "/auth", DerobotWeb do
    pipe_through [:sso_session]
    get "/:provider", SSOController, :oauth_request
    get "/:provider/callback", SSOController, :oauth_callback
  end

  if Application.compile_env(:derobot, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: DerobotWeb.Telemetry
    end
  end
end
