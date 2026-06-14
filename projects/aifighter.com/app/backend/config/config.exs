import Config

config :seed_helper,
  repo: Aifighter.Repo

config :smart_token,
  repo: Aifighter.Repo

config :aifighter, Aifighter.Repo,
  types: Aifighter.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :aifighter,
  ecto_repos: [Aifighter.Repo],
  generators: [timestamp_type: :utc_datetime]

config :aifighter, AifighterWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AifighterWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Aifighter.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :aifighter, :mail_from,
  {"AiFighter", "noreply@aifighter.com"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :aifighter, :redis, uri: "redis://localhost:6379/0", key_prefix: "aifighter:"

config :aifighter, Aifighter.Guardian,
  issuer: "aifighter",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :aifighter, :oidc_enabled, false
config :aifighter, :saml_enabled, false
config :aifighter, :google_enabled, false
config :aifighter, :facebook_enabled, false
config :aifighter, :github_enabled, false
config :aifighter, :linkedin_enabled, false
config :aifighter, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: AifighterWeb.SAMLHandler

# Background jobs
config :aifighter, Oban,
  repo: Aifighter.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Aifighter.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :aifighter, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :aifighter, AifighterWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
