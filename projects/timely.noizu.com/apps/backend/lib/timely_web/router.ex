defmodule TimelyWeb.Router do
  use TimelyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug TimelyWeb.AuthPipeline
  end

  pipeline :sso_session do
    plug Plug.Session,
      store: :cookie,
      key: "_timely_sso",
      signing_salt: "sso_session_salt",
      same_site: "Lax",
      # 15 minutes, raised from 5. This cookie carries the whole of an SSO
      # flow's in-flight state - the CSRF `state`, the OIDC `nonce`, the
      # validated redirect target and the PKCE challenge - and it has to outlive
      # the user's round trip through the identity provider. Five minutes is not
      # enough for a password plus a 2FA prompt typed on a phone, and expiring
      # mid-flow surfaces as an opaque `state_mismatch` rather than as anything
      # a user could act on. It holds flow state, never credentials.
      max_age: 900

    plug :fetch_session
  end

  pipeline :rate_limited_auth do
    plug TimelyWeb.Plugs.RateLimit, action: :auth
  end

  pipeline :rate_limited_sensitive do
    plug TimelyWeb.Plugs.RateLimit, action: :auth_sensitive
  end

  pipeline :org_viewer do
    plug TimelyWeb.Plugs.RequireRole, role: "viewer"
  end

  pipeline :org_editor do
    plug TimelyWeb.Plugs.RequireRole, role: "editor"
  end

  pipeline :org_admin do
    plug TimelyWeb.Plugs.RequireRole, role: "admin"
  end

  pipeline :org_owner do
    plug TimelyWeb.Plugs.RequireRole, role: "owner"
  end

  pipeline :admin do
    plug TimelyWeb.Plugs.RequireAdmin
  end

  scope "/", TimelyWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # App-association documents for verified deep links. Deliberately outside
  # EVERY pipeline: both platforms' verifiers fetch these unauthenticated, with
  # no cookies, and will not follow a redirect. The Apple document is served
  # from an extensionless path, which is why it does not go through
  # `plug :accepts, ["json"]`.
  scope "/.well-known", TimelyWeb do
    get "/assetlinks.json", WellKnownController, :assetlinks
    get "/apple-app-site-association", WellKnownController, :apple_app_site_association
  end

  scope "/api/v1", TimelyWeb do
    pipe_through [:api, :rate_limited_auth]
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
    get "/consent/cookies", ConsentController, :show
    put "/consent/cookies", ConsentController, :update
    get "/auth/sso/providers", SSOController, :providers
    post "/auth/sso/exchange", SSOController, :exchange
    get "/config/features", ConfigController, :features
  end

  scope "/api/v1", TimelyWeb do
    pipe_through [:api, :rate_limited_sensitive]
    post "/auth/magic-link", AuthController, :request_magic_link
    post "/auth/magic-link/verify", AuthController, :verify_magic_link
    post "/auth/otp-login", AuthController, :request_otp_login
    post "/auth/otp-login/verify", AuthController, :verify_otp_login
    post "/auth/password-reset", AuthController, :request_password_reset
    post "/auth/password-reset/verify", AuthController, :verify_password_reset
    post "/auth/verify-email/confirm", AuthController, :verify_email
  end

  scope "/api/v1", TimelyWeb do
    pipe_through [:api, :authenticated]
    get "/auth/me", AuthController, :me
    post "/auth/verify-email", AuthController, :send_verification
    get "/users/me", UserController, :show
    patch "/users/me", UserController, :update
    post "/users/me/complete-registration", UserController, :complete_registration
    resources "/organizations", OrganizationController, only: [:index, :create, :show]
    post "/media/presign", MediaController, :presign
    post "/media/download", MediaController, :download
    post "/media/register", MediaController, :register
  end

  scope "/api/v1/organizations/:org_id", TimelyWeb do
    pipe_through [:api, :authenticated, :org_admin]
    resources "/members", MembershipController, only: [:index, :create, :update, :delete]
  end

  scope "/api/v1/admin", TimelyWeb do
    pipe_through [:api, :authenticated, :admin]
    get "/users", AdminController, :list_users
    get "/users/:id", AdminController, :show_user
    post "/users/:id/approve", AdminController, :approve_user
    get "/organizations", AdminController, :list_organizations
    get "/organizations/:id", AdminController, :show_organization
  end

  # Media serving (public/conditional auth — checked inline in controller)
  scope "/media", TimelyWeb do
    pipe_through [:api]
    get "/:short_id", MediaServeController, :show
    get "/:short_id/*filename", MediaServeController, :show
  end

  # SAML 2.0 (Samly handles assertion consumer service, metadata, etc.)
  scope "/sso/saml" do
    pipe_through [:sso_session]
    forward "/", Samly.Router
  end

  # OIDC redirect flow
  scope "/auth/oidc", TimelyWeb do
    pipe_through [:sso_session]
    get "/", SSOController, :oidc_init
    get "/callback", SSOController, :oidc_callback
  end

  # Social OAuth (ueberauth handles request + callback)
  scope "/auth", TimelyWeb do
    pipe_through [:sso_session]
    get "/:provider", SSOController, :oauth_request
    get "/:provider/callback", SSOController, :oauth_callback
  end

  # Timely sync API (docs/SYNC-PROTOCOL.md, apps/shared/contracts/timely-api.yaml).
  #
  # Every action authorizes the caller against the workspace named in the
  # request before it touches a row, and every query is workspace-scoped, so
  # membership is checked once and isolation is enforced in the query layer
  # rather than by filtering results afterwards.
  scope "/api/v1", TimelyWeb do
    pipe_through [:api, :authenticated]

    post "/devices", DeviceController, :create
    patch "/devices/:device_id", DeviceController, :update

    get "/sync/changes", SyncController, :changes
    post "/sync/mutations", SyncController, :mutations

    get "/screenshots/:screenshot_id", ScreenshotController, :show
    get "/reports/summary", ReportController, :summary
  end

  # The blob routes are separate because they exchange raw image bytes rather
  # than JSON, so they must not go through the `:accepts, ["json"]` plug.
  scope "/api/v1", TimelyWeb do
    pipe_through [:authenticated]

    post "/screenshots/:screenshot_id/blob", ScreenshotController, :upload
    get "/screenshots/:screenshot_id/blob", ScreenshotController, :download
  end

  # PBAC v2: Groups & Memberships (authenticated, read-only)
  scope "/api/v1", TimelyWeb do
    pipe_through [:api, :authenticated]

    get "/groups", GroupController, :index
    get "/groups/:id", GroupController, :show
    get "/groups/:id/policies", GroupController, :policies

    get "/memberships/me", AuthzMembershipController, :my_memberships
    get "/memberships/organizations/:org_id", AuthzMembershipController, :org_members
    get "/memberships/projects/:project_id", AuthzMembershipController, :project_members

    get "/policies/me", PolicyController, :my_policies
    post "/policies/check", PolicyController, :check
    post "/policies/explain", PolicyController, :explain
  end

  # PBAC v2: Projects (authenticated, permission-checked per action)
  scope "/api/v1/organizations/:org_id", TimelyWeb do
    pipe_through [:api, :authenticated]

    resources "/projects", ProjectController, only: [:index, :create, :show, :update, :delete]

    scope "/projects/:project_id" do
      post "/archive", ProjectController, :archive
      post "/unarchive", ProjectController, :unarchive
      post "/leave", ProjectController, :leave
      get "/members", ProjectController, :members
      post "/members", ProjectController, :add_member
      patch "/members/:member_user_id", ProjectController, :update_member
      delete "/members/:member_user_id", ProjectController, :remove_member
    end
  end

  # PBAC v2: Custom Roles (authenticated, permission-checked per action)
  scope "/api/v1/organizations/:org_id", TimelyWeb do
    pipe_through [:api, :authenticated]

    resources "/roles", CustomRoleController, only: [:index, :create, :show, :update, :delete]

    scope "/roles/:role_id" do
      get "/permissions", CustomRoleController, :show
      post "/permissions", CustomRoleController, :add_permission
      delete "/permissions/:permission_id", CustomRoleController, :remove_permission
    end
  end

  # PBAC v2: Policy admin (admin only)
  scope "/api/v1", TimelyWeb do
    pipe_through [:api, :authenticated, :admin]

    resources "/policies", PolicyController, only: [:index, :create, :show, :update, :delete]
    post "/users/:user_id/policies", PolicyController, :attach_to_user
    delete "/users/:user_id/policies/:policy_id", PolicyController, :detach_from_user
  end

  if Application.compile_env(:timely, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: TimelyWeb.Telemetry
    end
  end
end
