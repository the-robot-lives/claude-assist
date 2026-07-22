import Config

config :seed_helper,
  repo: GottaCc.Repo

config :smart_token,
  repo: GottaCc.Repo

config :gotta_cc, GottaCc.Repo,
  types: GottaCc.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :gotta_cc,
  ecto_repos: [GottaCc.Repo],
  generators: [timestamp_type: :utc_datetime]

config :gotta_cc, GottaCcWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: GottaCcWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GottaCc.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :gotta_cc, :mail_from,
  {"GottaCc", "noreply@gotta.cc"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :gotta_cc, :redis, uri: "redis://localhost:6379/0", key_prefix: "gotta_cc:"

config :gotta_cc, GottaCc.Guardian,
  issuer: "gotta_cc",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :gotta_cc, :oidc_enabled, false
config :gotta_cc, :saml_enabled, false
config :gotta_cc, :google_enabled, false
config :gotta_cc, :facebook_enabled, false
config :gotta_cc, :github_enabled, false
config :gotta_cc, :linkedin_enabled, false
config :gotta_cc, :sso_require_invite, false

# Open self-registration: when true, POST /api/v1/auth/register accepts a bare
# {user: {...}} body (no invite_token) and creates an unverified account. The
# public directory needs this so anyone can register and submit sites. Set to
# false to force invite-only registration.
config :gotta_cc, :open_registration, true

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: GottaCcWeb.SAMLHandler

# Background jobs
config :gotta_cc, Oban,
  repo: GottaCc.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", GottaCc.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :gotta_cc, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :gotta_cc, GottaCcWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
