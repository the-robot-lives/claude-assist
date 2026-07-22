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
      key: "_tobornalp_sso",
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

  scope "/", host: "personal." do
    pipe_through [:api]

    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Personal.MCP)
  end

  scope "/", host: "artifacts." do
    pipe_through [:api]

    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Artifacts.MCP)
  end

  scope "/", host: "wiki." do
    pipe_through [:api]

    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Wiki.MCP)
  end

  scope "/", host: "review." do
    pipe_through [:api]

    forward "/mcp",
            Noizu.MCP.Transport.StreamableHTTP.Plug,
            TherobotplansWeb.MCPConfig.plug_opts(Therobotplans.Domains.Review.MCP)
  end

  scope "/api/v1", TherobotplansWeb do
    pipe_through [:api, :rate_limited_auth]
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
    get "/auth/sso/providers", SSOController, :providers
    post "/auth/sso/exchange", SSOController, :exchange
    get "/auth/sso/registration", SSOController, :registration
    post "/auth/sso/register", SSOController, :register
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
    post "/users/me/complete-registration", UserController, :complete_registration
    put "/users/active/consent", UserController, :consent

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
    post "/users/:id/approve", AdminController, :approve_user
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
      post "/provision", ProjectController, :provision
      get "/members", ProjectController, :members
      post "/members", ProjectController, :add_member
      patch "/members/:member_user_id", ProjectController, :update_member
      delete "/members/:member_user_id", ProjectController, :remove_member
    end

    # Items (work tracking) — basic CRUD. :id accepts UUID or human key (PREFIX-NNN).
    resources "/items", ItemController, only: [:index, :create, :show, :update, :delete]
    get "/items/:id/activity", ItemController, :activity
    get "/items/:id/links", ItemController, :links
    post "/items/:id/links", ItemController, :create_link
    delete "/items/links/:id", ItemController, :delete_link
    get "/items/:id/comments", ItemController, :comments
    post "/items/:id/comments", ItemController, :create_comment
    delete "/items/comments/:id", ItemController, :delete_comment

    # Artifacts (versioned typed content) — code/document/image/wiki/config/binary.
    resources "/artifacts", ArtifactController, only: [:index, :create, :show]
    get "/artifacts/:artifact_id/revisions", ArtifactController, :index_revisions
    post "/artifacts/:artifact_id/revisions", ArtifactController, :create_revision

    # Wiki — spaces, pages, comments, attachments, reactions.
    get "/wiki/spaces", WikiController, :index_spaces
    post "/wiki/spaces", WikiController, :create_space
    get "/wiki/spaces/:id", WikiController, :show_space
    put "/wiki/spaces/:id", WikiController, :update_space
    delete "/wiki/spaces/:id", WikiController, :delete_space
    get "/wiki/spaces/:space_id/pages", WikiController, :index_pages
    post "/wiki/spaces/:space_id/pages", WikiController, :create_page
    get "/wiki/pages/:id", WikiController, :show_page
    put "/wiki/pages/:id", WikiController, :update_page
    delete "/wiki/pages/:id", WikiController, :delete_page
    get "/wiki/pages/:page_id/comments", WikiController, :index_comments
    post "/wiki/pages/:page_id/comments", WikiController, :create_comment
    delete "/wiki/comments/:id", WikiController, :delete_comment
    get "/wiki/pages/:page_id/attachments", WikiController, :index_attachments
    post "/wiki/pages/:page_id/attachments", WikiController, :create_attachment
    delete "/wiki/attachments/:id", WikiController, :delete_attachment
    get "/wiki/pages/:page_id/reactions", WikiController, :index_page_reactions
    post "/wiki/pages/:page_id/reactions", WikiController, :add_page_reaction
    delete "/wiki/pages/:page_id/reactions", WikiController, :remove_page_reaction
    get "/wiki/comments/:comment_id/reactions", WikiController, :index_comment_reactions
    post "/wiki/comments/:comment_id/reactions", WikiController, :add_comment_reaction
    delete "/wiki/comments/:comment_id/reactions", WikiController, :remove_comment_reaction

    # Boards (queues) — methodology-aware kanban/scrum/waterfall/spiral boards.
    resources "/queues", QueueController, only: [:index, :create, :show, :update, :delete]
    get "/queues/:queue_id/stages", QueueController, :stages
    post "/queues/:queue_id/stages", QueueController, :create_stage
    put "/queues/:queue_id/stages/:id", QueueController, :update_stage
    delete "/queues/:queue_id/stages/:id", QueueController, :delete_stage
    get "/queues/:queue_id/iterations", QueueController, :iterations
    post "/queues/:queue_id/iterations", QueueController, :create_iteration
    put "/queues/:queue_id/iterations/:id", QueueController, :update_iteration
    delete "/queues/:queue_id/iterations/:id", QueueController, :delete_iteration

    # Saved views — per-user/project persisted list/board filters.
    resources "/saved-views", SavedViewController, only: [:index, :create, :show, :update, :delete]
    # Reviews — code/content reviews over an artifact revision.
    resources "/reviews", ReviewController, only: [:index, :create, :show, :update]
    post "/reviews/:review_id/complete", ReviewController, :complete

    # Tri-scoped item type/field definitions.
    get "/definitions/fields", DefinitionController, :index_fields
    post "/definitions/fields", DefinitionController, :create_field
    get "/definitions/types", DefinitionController, :index_types
    post "/definitions/types", DefinitionController, :create_type

    get "/definitions/fields/:id", DefinitionController, :show_field
    put "/definitions/fields/:id", DefinitionController, :update_field
    patch "/definitions/fields/:id", DefinitionController, :update_field
    delete "/definitions/fields/:id", DefinitionController, :delete_field

    get "/definitions/types/:id", DefinitionController, :show_type
    put "/definitions/types/:id", DefinitionController, :update_type
    patch "/definitions/types/:id", DefinitionController, :update_type
    delete "/definitions/types/:id", DefinitionController, :delete_type

    post "/definitions/types/:id/fields", DefinitionController, :add_field
    delete "/definitions/types/:id/fields/:field_id", DefinitionController, :remove_field

    # Notifications inbox (recipient = authenticated user).
    get "/notifications", NotificationController, :index
    get "/notifications/count", NotificationController, :count
    post "/notifications/mark_read", NotificationController, :mark_read

    # Personal items (per-user lightweight tasks, tags, recurrence).
    scope "/personal" do
      get "/items", PersonalItemController, :index
      get "/tags", PersonalItemController, :tags
      post "/items", PersonalItemController, :create
      patch "/items/:id", PersonalItemController, :update
      post "/items/:id/complete", PersonalItemController, :complete
      post "/items/:id/recurrence", PersonalItemController, :set_recurrence
      delete "/items/:id/recurrence", PersonalItemController, :clear_recurrence
    end

    # OKRs (objectives + key results + check-ins).
    # ORDER MATTERS: /objectives/tree MUST precede the resources block, else
    # "tree" is captured as :id.
    get "/objectives/tree", OkrController, :tree
    resources "/objectives", OkrController, only: [:index, :create, :show, :update, :delete]
    post "/objectives/:id/children", OkrController, :create_child
    post "/objectives/:id/key_results", OkrController, :create_key_result
    post "/objectives/:id/checkins", OkrController, :create_checkin
    get "/objectives/:id/checkins", OkrController, :list_checkins
    patch "/key_results/:id", OkrController, :update_key_result
    delete "/key_results/:id", OkrController, :delete_key_result
    post "/key_results/:id/items", OkrController, :link_item
    delete "/key_results/:id/items/:item_id", OkrController, :unlink_item
    delete "/checkins/:id", OkrController, :delete_checkin
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
  # scopes so the per-domain hosts win for those hosts. No alias prefix here:
  # the forward target is the fully-qualified Noizu.MCP plug, so a scope alias
  # would corrupt it to TherobotplansWeb.Noizu.MCP.* (mirrors the host scopes).
  scope "/" do
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
