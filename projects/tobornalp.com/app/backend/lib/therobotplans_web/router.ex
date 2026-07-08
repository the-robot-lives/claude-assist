defmodule TherobotplansWeb.Router do
  use TherobotplansWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug TherobotplansWeb.AuthPipeline
  end

  pipeline :sso_session do
    plug Plug.Session,
      store: :cookie,
      key: "_starter_sso",
      signing_salt: "sso_session_salt",
      same_site: "Lax",
      max_age: 300
    plug :fetch_session
  end

  pipeline :rate_limited_auth do
    plug TherobotplansWeb.Plugs.RateLimit, action: :auth
  end

  pipeline :rate_limited_sensitive do
    plug TherobotplansWeb.Plugs.RateLimit, action: :auth_sensitive
  end

  pipeline :org_viewer do
    plug TherobotplansWeb.Plugs.RequireRole, role: "viewer"
  end

  pipeline :org_editor do
    plug TherobotplansWeb.Plugs.RequireRole, role: "editor"
  end

  pipeline :org_admin do
    plug TherobotplansWeb.Plugs.RequireRole, role: "admin"
  end

  pipeline :org_owner do
    plug TherobotplansWeb.Plugs.RequireRole, role: "owner"
  end

  pipeline :admin do
    plug TherobotplansWeb.Plugs.RequireAdmin
  end

  scope "/", TherobotplansWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # MCP JWT bootstrap — exchange a raw MCP API key for a short-lived MCP JWT.
  # Unauthenticated (the raw key IS the credential). Identity is taken from the
  # verified key's owner row, never from request-supplied ids.
  scope "/api/mcp", TherobotplansWeb do
    pipe_through [:api, :rate_limited_auth]
    post "/token", TokenController, :create
  end

  # ── MCP server endpoints ─────────────────────────────────────────────────
  # Each domain server is mounted on its own subdomain at `/mcp`; the root
  # aggregator serves the bare host at `/mcp`. Requests must present a Bearer
  # MCP JWT (see TherobotplansWeb.MCPConfig). NOTE: keep these host: scopes in
  # sync with the Therobotplans.MCPServers catalog and the application.ex
  # children list — a server missing from any of the three is dead.
  scope "/", host: "projects." do
    pipe_through [:api]
    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.MCP.Projects)
  end

  scope "/", host: "items." do
    pipe_through [:api]
    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Items.MCP)
  end

  scope "/", host: "notifications." do
    pipe_through [:api]
    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Notifications.MCP)
  end

  scope "/", host: "goals." do
    pipe_through [:api]
    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Goals.MCP)
  end

  scope "/api/v1", TherobotplansWeb do
    pipe_through [:api, :rate_limited_auth]
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
    get "/auth/sso/providers", SSOController, :providers
    post "/auth/sso/exchange", SSOController, :exchange
    get "/config/features", ConfigController, :features
  end

  scope "/api/v1", TherobotplansWeb do
    pipe_through [:api, :rate_limited_sensitive]
    post "/auth/magic-link", AuthController, :request_magic_link
    post "/auth/magic-link/verify", AuthController, :verify_magic_link
    post "/auth/otp-login", AuthController, :request_otp_login
    post "/auth/otp-login/verify", AuthController, :verify_otp_login
    post "/auth/password-reset", AuthController, :request_password_reset
    post "/auth/password-reset/verify", AuthController, :verify_password_reset
    post "/auth/verify-email/confirm", AuthController, :verify_email
  end

  scope "/api/v1", TherobotplansWeb do
    pipe_through [:api, :authenticated]
    get "/auth/me", AuthController, :me
    post "/auth/verify-email", AuthController, :send_verification
    get "/users/me", UserController, :show
    patch "/users/me", UserController, :update

    # Today view — unified "what do I do now" plan for the authenticated user.
    get "/today", TodayController, :show
    resources "/organizations", OrganizationController, only: [:index, :create, :show]
    post "/media/presign", MediaController, :presign
    post "/media/download", MediaController, :download
    post "/media/register", MediaController, :register
  end

  scope "/api/v1/organizations/:org_id", TherobotplansWeb do
    pipe_through [:api, :authenticated, :org_admin]
    resources "/members", MembershipController, only: [:index, :create, :update, :delete]
  end

  scope "/api/v1/admin", TherobotplansWeb do
    pipe_through [:api, :authenticated, :admin]
    get "/users", AdminController, :list_users
    get "/users/:id", AdminController, :show_user
    get "/organizations", AdminController, :list_organizations
    get "/organizations/:id", AdminController, :show_organization
  end

  # Media serving (public/conditional auth — checked inline in controller)
  scope "/media", TherobotplansWeb do
    pipe_through [:api]
    get "/:short_id", MediaServeController, :show
    get "/:short_id/*filename", MediaServeController, :show
  end

  # SAML 2.0 (Samly handles assertion consumer service, metadata, etc.)
  if Application.compile_env(:therobotplans, :saml_enabled) do
    scope "/sso/saml" do
      pipe_through [:sso_session]
      forward "/", Samly.Router
    end
  end

  # OIDC redirect flow
  scope "/auth/oidc", TherobotplansWeb do
    pipe_through [:sso_session]
    get "/", SSOController, :oidc_init
    get "/callback", SSOController, :oidc_callback
  end

  # Social OAuth (ueberauth handles request + callback)
  scope "/auth", TherobotplansWeb do
    pipe_through [:sso_session]
    get "/:provider", SSOController, :oauth_request
    get "/:provider/callback", SSOController, :oauth_callback
  end

  # PBAC v2: Groups & Memberships (authenticated, read-only)
  scope "/api/v1", TherobotplansWeb do
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
  scope "/api/v1/organizations/:org_id", TherobotplansWeb do
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

    # Items (work tracking) — basic CRUD. :id accepts UUID or human key (PREFIX-NNN).
    resources "/items", ItemController, only: [:index, :create, :show, :update]

    # Boards (queues) — methodology-aware kanban/scrum/waterfall/spiral boards.
    resources "/queues", QueueController, only: [:index, :create, :show, :update]

    # Tri-scoped item type/field definitions.
    get "/definitions/fields", DefinitionController, :index_fields
    post "/definitions/fields", DefinitionController, :create_field
    get "/definitions/types", DefinitionController, :index_types
    post "/definitions/types", DefinitionController, :create_type

    # Notifications inbox (recipient = authenticated user).
    get "/notifications", NotificationController, :index
    get "/notifications/count", NotificationController, :count
    post "/notifications/mark_read", NotificationController, :mark_read

    # OKRs (objectives + key results + check-ins).
    resources "/objectives", OkrController, only: [:index, :create, :show, :update]
    post "/objectives/:id/key_results", OkrController, :create_key_result
    post "/objectives/:id/checkins", OkrController, :create_checkin
  end

  # PBAC v2: Custom Roles (authenticated, permission-checked per action)
  scope "/api/v1/organizations/:org_id", TherobotplansWeb do
    pipe_through [:api, :authenticated]

    resources "/roles", CustomRoleController, only: [:index, :create, :show, :update, :delete]

    scope "/roles/:role_id" do
      get "/permissions", CustomRoleController, :show
      post "/permissions", CustomRoleController, :add_permission
      delete "/permissions/:permission_id", CustomRoleController, :remove_permission
    end
  end

  # PBAC v2: Policy admin (admin only)
  scope "/api/v1", TherobotplansWeb do
    pipe_through [:api, :authenticated, :admin]

    resources "/policies", PolicyController, only: [:index, :create, :show, :update, :delete]
    post "/users/:user_id/policies", PolicyController, :attach_to_user
    delete "/users/:user_id/policies/:policy_id", PolicyController, :detach_from_user
  end

  # MCP connection config (host + server list) for building setup commands.
  scope "/api/v1", TherobotplansWeb do
    pipe_through [:api, :authenticated]
    get "/auth/mcp/config", AuthController, :mcp_config
  end

  # Root MCP aggregator — bare host `/mcp`. Must come after the subdomain
  # scopes so the per-domain hosts win for those hosts.
  scope "/", TherobotplansWeb do
    pipe_through [:api]
    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.MCP)
  end

  if Application.compile_env(:therobotplans, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: TherobotplansWeb.Telemetry
    end
  end
end
