import Config

config :seed_helper,
  repo: Therobotplans.Repo

config :smart_token,
  repo: Therobotplans.Repo

config :therobotplans, Therobotplans.Repo,
  types: Therobotplans.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :therobotplans,
  ecto_repos: [Therobotplans.Repo],
  generators: [timestamp_type: :utc_datetime]

config :therobotplans, TherobotplansWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TherobotplansWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Therobotplans.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :therobotplans, :mail_from, {"Therobotplans", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :therobotplans, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :therobotplans, Therobotplans.Guardian,
  issuer: "therobotplans",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :therobotplans, :oidc_enabled, false
config :therobotplans, :saml_enabled, false
config :therobotplans, :google_enabled, false
config :therobotplans, :facebook_enabled, false
config :therobotplans, :github_enabled, false
config :therobotplans, :linkedin_enabled, false
config :therobotplans, :sso_require_invite, false
config :therobotplans, :sso_domains, %{}
config :therobotplans, :sso_auto_approve_domains, []
config :therobotplans, :sso_domain_policies, %{}

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider, pipeline_handler: TherobotplansWeb.SAMLHandler

# Background jobs
config :therobotplans, Oban,
  repo: Therobotplans.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Therobotplans.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :therobotplans, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :therobotplans, TherobotplansWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
