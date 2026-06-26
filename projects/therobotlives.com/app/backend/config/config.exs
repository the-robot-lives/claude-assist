import Config

config :seed_helper,
  repo: Therobotlives.Repo

config :smart_token,
  repo: Therobotlives.Repo

config :therobotlives, Therobotlives.Repo,
  types: Therobotlives.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :therobotlives,
  ecto_repos: [Therobotlives.Repo],
  generators: [timestamp_type: :utc_datetime]

config :therobotlives, TherobotlivesWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TherobotlivesWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Therobotlives.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :therobotlives, :mail_from,
  {"Therobotlives", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :therobotlives, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :therobotlives, Therobotlives.Guardian,
  issuer: "therobotlives",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :therobotlives, :oidc_enabled, false
config :therobotlives, :saml_enabled, false
config :therobotlives, :google_enabled, false
config :therobotlives, :facebook_enabled, false
config :therobotlives, :github_enabled, false
config :therobotlives, :linkedin_enabled, false
config :therobotlives, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: TherobotlivesWeb.SAMLHandler

# Background jobs
config :therobotlives, Oban,
  repo: Therobotlives.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Therobotlives.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :therobotlives, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :therobotlives, TherobotlivesWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
