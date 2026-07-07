import Config

config :seed_helper,
  repo: DesigningDerobot.Repo

config :smart_token,
  repo: DesigningDerobot.Repo

config :designing_derobot, DesigningDerobot.Repo,
  types: DesigningDerobot.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :designing_derobot,
  ecto_repos: [DesigningDerobot.Repo],
  generators: [timestamp_type: :utc_datetime]

config :designing_derobot, DesigningDerobotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: DesigningDerobotWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DesigningDerobot.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :designing_derobot, :mail_from,
  {"DesigningDerobot", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :designing_derobot, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :designing_derobot, DesigningDerobot.Guardian,
  issuer: "designing_derobot",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :designing_derobot, :oidc_enabled, false
config :designing_derobot, :saml_enabled, false
config :designing_derobot, :google_enabled, false
config :designing_derobot, :facebook_enabled, false
config :designing_derobot, :github_enabled, false
config :designing_derobot, :linkedin_enabled, false
config :designing_derobot, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: DesigningDerobotWeb.SAMLHandler

# Background jobs
config :designing_derobot, Oban,
  repo: DesigningDerobot.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", DesigningDerobot.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :designing_derobot, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :designing_derobot, DesigningDerobotWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
