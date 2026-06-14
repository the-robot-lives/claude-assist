import Config

config :seed_helper,
  repo: Iotgo.Repo

config :smart_token,
  repo: Iotgo.Repo

config :iotgo, Iotgo.Repo,
  types: Iotgo.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :iotgo,
  ecto_repos: [Iotgo.Repo],
  generators: [timestamp_type: :utc_datetime]

config :iotgo, IotgoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: IotgoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Iotgo.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :iotgo, :mail_from,
  {"IoTGo", "noreply@iotgo.io"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :iotgo, :redis, uri: "redis://localhost:6379/0", key_prefix: "iotgo:"

config :iotgo, Iotgo.Guardian,
  issuer: "iotgo",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :iotgo, :oidc_enabled, false
config :iotgo, :saml_enabled, false
config :iotgo, :google_enabled, false
config :iotgo, :facebook_enabled, false
config :iotgo, :github_enabled, false
config :iotgo, :linkedin_enabled, false
config :iotgo, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: IotgoWeb.SAMLHandler

# Background jobs
config :iotgo, Oban,
  repo: Iotgo.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Iotgo.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :iotgo, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :iotgo, IotgoWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
