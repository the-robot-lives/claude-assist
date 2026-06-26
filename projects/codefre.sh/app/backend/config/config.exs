import Config

config :seed_helper,
  repo: Codefresh.Repo

config :smart_token,
  repo: Codefresh.Repo

config :codefresh, Codefresh.Repo,
  types: Codefresh.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :codefresh,
  ecto_repos: [Codefresh.Repo],
  generators: [timestamp_type: :utc_datetime]

config :codefresh, CodefreshWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: CodefreshWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Codefresh.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :codefresh, :mail_from,
  {"Codefresh", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :codefresh, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :codefresh, Codefresh.Guardian,
  issuer: "codefresh",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :codefresh, :oidc_enabled, false
config :codefresh, :saml_enabled, false
config :codefresh, :google_enabled, false
config :codefresh, :facebook_enabled, false
config :codefresh, :github_enabled, false
config :codefresh, :linkedin_enabled, false
config :codefresh, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: CodefreshWeb.SAMLHandler

# Background jobs
config :codefresh, Oban,
  repo: Codefresh.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5, runner: 5, scheduled: 2, webhook: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Codefresh.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :codefresh, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :codefresh, CodefreshWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
