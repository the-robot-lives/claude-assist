import Config

config :seed_helper,
  repo: Jailbreaking.Repo

config :smart_token,
  repo: Jailbreaking.Repo

config :jailbreaking, Jailbreaking.Repo,
  types: Jailbreaking.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :jailbreaking,
  ecto_repos: [Jailbreaking.Repo],
  generators: [timestamp_type: :utc_datetime]

config :jailbreaking, JailbreakingWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: JailbreakingWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Jailbreaking.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :jailbreaking, :mail_from,
  {"JailbreakingSite", "noreply@jailbreakingsite.com"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :jailbreaking, :redis, uri: "redis://localhost:6379/0", key_prefix: "jailbreaking:"

config :jailbreaking, Jailbreaking.Guardian,
  issuer: "jailbreaking",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :jailbreaking, :oidc_enabled, false
config :jailbreaking, :saml_enabled, false
config :jailbreaking, :google_enabled, false
config :jailbreaking, :facebook_enabled, false
config :jailbreaking, :github_enabled, false
config :jailbreaking, :linkedin_enabled, false
config :jailbreaking, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: JailbreakingWeb.SAMLHandler

# Background jobs
config :jailbreaking, Oban,
  repo: Jailbreaking.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Jailbreaking.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :jailbreaking, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :jailbreaking, JailbreakingWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
