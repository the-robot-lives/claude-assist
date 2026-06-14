import Config

config :seed_helper,
  repo: NoizuSite.Repo

config :smart_token,
  repo: NoizuSite.Repo

config :noizu_site, NoizuSite.Repo,
  types: NoizuSite.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :noizu_site,
  ecto_repos: [NoizuSite.Repo],
  generators: [timestamp_type: :utc_datetime]

config :noizu_site, NoizuSiteWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: NoizuSiteWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: NoizuSite.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :noizu_site, :mail_from,
  {"Noizu", "noreply@noizu.com"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :noizu_site, :redis, uri: "redis://localhost:6379/0", key_prefix: "noizu_site:"

config :noizu_site, NoizuSite.Guardian,
  issuer: "noizu_site",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :noizu_site, :oidc_enabled, false
config :noizu_site, :saml_enabled, false
config :noizu_site, :google_enabled, false
config :noizu_site, :facebook_enabled, false
config :noizu_site, :github_enabled, false
config :noizu_site, :linkedin_enabled, false
config :noizu_site, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: NoizuSiteWeb.SAMLHandler

# Background jobs
config :noizu_site, Oban,
  repo: NoizuSite.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", NoizuSite.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :noizu_site, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :noizu_site, NoizuSiteWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
