import Config

config :seed_helper,
  repo: Therobotmakes.Repo

config :smart_token,
  repo: Therobotmakes.Repo

config :therobotmakes, Therobotmakes.Repo,
  types: Therobotmakes.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :therobotmakes,
  ecto_repos: [Therobotmakes.Repo],
  generators: [timestamp_type: :utc_datetime]

config :therobotmakes, TherobotmakesWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TherobotmakesWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Therobotmakes.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :therobotmakes, :mail_from,
  {"Therobotmakes", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :therobotmakes, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :therobotmakes, Therobotmakes.Guardian,
  issuer: "therobotmakes",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :therobotmakes, :oidc_enabled, false
config :therobotmakes, :saml_enabled, false
config :therobotmakes, :google_enabled, false
config :therobotmakes, :facebook_enabled, false
config :therobotmakes, :github_enabled, false
config :therobotmakes, :linkedin_enabled, false
config :therobotmakes, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: TherobotmakesWeb.SAMLHandler

# Background jobs
config :therobotmakes, Oban,
  repo: Therobotmakes.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Therobotmakes.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :therobotmakes, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :therobotmakes, TherobotmakesWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
