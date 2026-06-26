import Config

config :seed_helper,
  repo: Therobotsdayjob.Repo

config :smart_token,
  repo: Therobotsdayjob.Repo

config :therobotsdayjob, Therobotsdayjob.Repo,
  types: Therobotsdayjob.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :therobotsdayjob,
  ecto_repos: [Therobotsdayjob.Repo],
  generators: [timestamp_type: :utc_datetime]

config :therobotsdayjob, TherobotsdayjobWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TherobotsdayjobWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Therobotsdayjob.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :therobotsdayjob, :mail_from,
  {"Therobotsdayjob", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :therobotsdayjob, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :therobotsdayjob, Therobotsdayjob.Guardian,
  issuer: "therobotsdayjob",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :therobotsdayjob, :oidc_enabled, false
config :therobotsdayjob, :saml_enabled, false
config :therobotsdayjob, :google_enabled, false
config :therobotsdayjob, :facebook_enabled, false
config :therobotsdayjob, :github_enabled, false
config :therobotsdayjob, :linkedin_enabled, false
config :therobotsdayjob, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: TherobotsdayjobWeb.SAMLHandler

# Background jobs
config :therobotsdayjob, Oban,
  repo: Therobotsdayjob.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Therobotsdayjob.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :therobotsdayjob, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :therobotsdayjob, TherobotsdayjobWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
