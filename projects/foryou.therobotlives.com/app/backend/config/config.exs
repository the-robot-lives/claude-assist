import Config

config :seed_helper,
  repo: Foryou.Repo

config :smart_token,
  repo: Foryou.Repo

config :foryou, Foryou.Repo,
  types: Foryou.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :foryou,
  ecto_repos: [Foryou.Repo],
  generators: [timestamp_type: :utc_datetime]

config :foryou, ForyouWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ForyouWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Foryou.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :foryou, :mail_from,
  {"Foryou", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :foryou, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :foryou, Foryou.Guardian,
  issuer: "foryou",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :foryou, :oidc_enabled, false
config :foryou, :saml_enabled, false
config :foryou, :google_enabled, false
config :foryou, :facebook_enabled, false
config :foryou, :github_enabled, false
config :foryou, :linkedin_enabled, false
config :foryou, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: ForyouWeb.SAMLHandler

# Background jobs
config :foryou, Oban,
  repo: Foryou.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Foryou.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :foryou, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :foryou, ForyouWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
