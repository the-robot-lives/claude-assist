import Config

config :seed_helper,
  repo: Therobotknows.Repo

config :smart_token,
  repo: Therobotknows.Repo

config :therobotknows, Therobotknows.Repo,
  types: Therobotknows.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :therobotknows,
  ecto_repos: [Therobotknows.Repo],
  generators: [timestamp_type: :utc_datetime]

config :therobotknows, TherobotknowsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TherobotknowsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Therobotknows.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :therobotknows, :mail_from,
  {"Therobotknows", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :therobotknows, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :therobotknows, Therobotknows.Guardian,
  issuer: "therobotknows",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :therobotknows, :oidc_enabled, false
config :therobotknows, :saml_enabled, false
config :therobotknows, :google_enabled, false
config :therobotknows, :facebook_enabled, false
config :therobotknows, :github_enabled, false
config :therobotknows, :linkedin_enabled, false
config :therobotknows, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: TherobotknowsWeb.SAMLHandler

# Background jobs
config :therobotknows, Oban,
  repo: Therobotknows.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Therobotknows.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :therobotknows, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :therobotknows, TherobotknowsWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
