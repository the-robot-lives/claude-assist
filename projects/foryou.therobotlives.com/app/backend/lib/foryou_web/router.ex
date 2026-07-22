defmodule ForyouWeb.Router do
  use ForyouWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug ForyouWeb.AuthPipeline
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
    plug ForyouWeb.Plugs.RateLimit, action: :auth
  end

  pipeline :rate_limited_sensitive do
    plug ForyouWeb.Plugs.RateLimit, action: :auth_sensitive
  end

  pipeline :rate_limited_inquiry do
    plug ForyouWeb.Plugs.RateLimit, action: :inquiry
  end

  pipeline :rate_limited_signup do
    plug ForyouWeb.Plugs.RateLimit, action: :signup
  end

  # Public signup confirm/unsubscribe render HTML pages, so they accept html
  # rather than forcing json (which would 406 a browser GET).
  pipeline :public_browser do
    plug :accepts, ["html"]
  end

  pipeline :org_viewer do
    plug ForyouWeb.Plugs.RequireRole, role: "viewer"
  end

  pipeline :org_editor do
    plug ForyouWeb.Plugs.RequireRole, role: "editor"
  end

  pipeline :org_admin do
    plug ForyouWeb.Plugs.RequireRole, role: "admin"
  end

  pipeline :org_owner do
    plug ForyouWeb.Plugs.RequireRole, role: "owner"
  end

  pipeline :admin do
    plug ForyouWeb.Plugs.RequireAdmin
  end

  pipeline :api_key do
    plug :accepts, ["json"]
    plug ForyouWeb.Plugs.ApiKeyAuth
  end

  scope "/", ForyouWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  scope "/api/v1", ForyouWeb do
    pipe_through [:api, :rate_limited_auth]
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
    get "/auth/sso/providers", SSOController, :providers
    post "/auth/sso/exchange", SSOController, :exchange
    get "/config/features", ConfigController, :features
  end

  scope "/api/v1", ForyouWeb do
    pipe_through [:api, :rate_limited_inquiry]
    post "/inquiries", InquiryController, :create
    post "/forms/:form_id/submit", FormSubmissionController, :submit
  end

  # Public signup surface — unauthenticated, CORS-open (endpoint-global plug),
  # rate-limited 5/60s per IP (D17), no-leak generic 202 (D2).
  scope "/api/v1/public", ForyouWeb do
    pipe_through [:api, :rate_limited_signup]
    post "/lists/:public_slug/signups", PublicSignupController, :create
    post "/services/:service_slug/lists/:list_slug/signups", PublicSignupController, :create_alias
    post "/signups/resend", PublicSignupController, :resend
  end

  # Public manifest reads (widget fetches the attribute schema at runtime).
  scope "/api/v1/public", ForyouWeb do
    pipe_through [:api]
    get "/lists/:public_slug", PublicSignupController, :manifest
    get "/services/:service_slug/lists/:list_slug", PublicSignupController, :manifest
  end

  # Public token confirm/unsubscribe (HTML, no login).
  scope "/api/v1/public", ForyouWeb do
    pipe_through [:public_browser]
    get "/signups/confirm", PublicSignupController, :confirm
    get "/signups/unsubscribe", PublicSignupController, :unsubscribe
  end

  scope "/api/v1", ForyouWeb do
    pipe_through [:api, :rate_limited_sensitive]
    post "/auth/magic-link", AuthController, :request_magic_link
    post "/auth/magic-link/verify", AuthController, :verify_magic_link
    post "/auth/otp-login", AuthController, :request_otp_login
    post "/auth/otp-login/verify", AuthController, :verify_otp_login
    post "/auth/password-reset", AuthController, :request_password_reset
    post "/auth/password-reset/verify", AuthController, :verify_password_reset
    post "/auth/verify-email/confirm", AuthController, :verify_email
  end

  scope "/api/v1", ForyouWeb do
    pipe_through [:api, :authenticated]
    get "/auth/me", AuthController, :me
    post "/auth/verify-email", AuthController, :send_verification
    get "/users/me", UserController, :show
    patch "/users/me", UserController, :update
    resources "/organizations", OrganizationController, only: [:index, :create, :show]
    post "/media/presign", MediaController, :presign
    post "/media/download", MediaController, :download
    post "/media/register", MediaController, :register
  end

  scope "/api/v1/organizations/:org_id", ForyouWeb do
    pipe_through [:api, :authenticated, :org_admin]
    resources "/members", MembershipController, only: [:index, :create, :update, :delete]
  end

  scope "/api/v1/admin", ForyouWeb do
    pipe_through [:api, :authenticated, :admin]
    get "/users", AdminController, :list_users
    get "/users/:id", AdminController, :show_user
    get "/organizations", AdminController, :list_organizations
    get "/organizations/:id", AdminController, :show_organization
  end

  # Management surface for API-key-authenticated clients (Terraform provider).
  # System-level keys grant full access.
  scope "/api/v1/management", ForyouWeb do
    pipe_through [:api_key]
    get "/ping", ManagementController, :ping

    resources "/users", Management.UserController, except: [:new, :edit]
    resources "/organizations", Management.OrganizationController, except: [:new, :edit]
    resources "/api-keys", Management.ApiKeyController, only: [:index, :show, :create, :delete]

    scope "/organizations/:org_id" do
      get "/memberships", Management.MembershipController, :index
      post "/memberships", Management.MembershipController, :create
      patch "/memberships/:user_id", Management.MembershipController, :update
      delete "/memberships/:user_id", Management.MembershipController, :delete
    end

    resources "/forms", Management.FormsController, except: [:new, :edit]
    get "/forms/:id/versions", Management.FormsController, :versions
    get "/forms/:id/submissions", Management.FormsController, :submissions

    # Lists (Terraform provider + listmonk backfill). System-level, no PBAC.
    resources "/lists", Management.ListsController, except: [:new, :edit]
    get "/lists/:id/signups", Management.ListsController, :signups
    post "/lists/:id/signups/import", Management.ListsController, :import_signups
    get "/lists/:id/attributes", Management.ListAttributesController, :index
    post "/lists/:id/attributes", Management.ListAttributesController, :create
    patch "/lists/:id/attributes/:attribute_id", Management.ListAttributesController, :update
    delete "/lists/:id/attributes/:attribute_id", Management.ListAttributesController, :delete
  end

  # Media serving (public/conditional auth — checked inline in controller)
  scope "/media", ForyouWeb do
    pipe_through [:api]
    get "/:short_id", MediaServeController, :show
    get "/:short_id/*filename", MediaServeController, :show
  end

  # SAML 2.0 (Samly handles assertion consumer service, metadata, etc.)
  if Application.compile_env(:foryou, :saml_enabled) do
    scope "/sso/saml" do
      pipe_through [:sso_session]
      forward "/", Samly.Router
    end
  end

  # OIDC redirect flow
  scope "/auth/oidc", ForyouWeb do
    pipe_through [:sso_session]
    get "/", SSOController, :oidc_init
    get "/callback", SSOController, :oidc_callback
  end

  # Social OAuth (ueberauth handles request + callback)
  scope "/auth", ForyouWeb do
    pipe_through [:sso_session]
    get "/:provider", SSOController, :oauth_request
    get "/:provider/callback", SSOController, :oauth_callback
  end

  # PBAC v2: Groups & Memberships (authenticated, read-only)
  scope "/api/v1", ForyouWeb do
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

  # Lists domain: authed project-scoped reads (admin console) + self-service.
  # Permissions inherit through the parent Service(project); writes go through
  # the system-level management API (TF), not here.
  scope "/api/v1", ForyouWeb do
    pipe_through [:api, :authenticated]

    get "/organizations/:org_id/projects/:project_id/lists", ListsController, :index
    get "/lists/:id", ListsController, :show
    get "/lists/:id/signups", ListsController, :signups

    get "/me/signups", MeController, :signups
    get "/me/inquiries", MeController, :inquiries
    delete "/me/signups/:id", MeController, :delete_signup
  end

  # PBAC v2: Projects (authenticated, permission-checked per action)
  scope "/api/v1/organizations/:org_id", ForyouWeb do
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
  scope "/api/v1/organizations/:org_id", ForyouWeb do
    pipe_through [:api, :authenticated]

    resources "/roles", CustomRoleController, only: [:index, :create, :show, :update, :delete]

    scope "/roles/:role_id" do
      get "/permissions", CustomRoleController, :show
      post "/permissions", CustomRoleController, :add_permission
      delete "/permissions/:permission_id", CustomRoleController, :remove_permission
    end
  end

  # PBAC v2: Policy admin (admin only)
  scope "/api/v1", ForyouWeb do
    pipe_through [:api, :authenticated, :admin]

    resources "/policies", PolicyController, only: [:index, :create, :show, :update, :delete]
    post "/users/:user_id/policies", PolicyController, :attach_to_user
    delete "/users/:user_id/policies/:policy_id", PolicyController, :detach_from_user
  end

  if Application.compile_env(:foryou, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: ForyouWeb.Telemetry
    end
  end
end
