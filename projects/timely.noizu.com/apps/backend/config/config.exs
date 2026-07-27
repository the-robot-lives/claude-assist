import Config

config :seed_helper,
  repo: Timely.Repo

config :smart_token,
  repo: Timely.Repo

config :timely, Timely.Repo,
  types: Timely.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :timely,
  ecto_repos: [Timely.Repo],
  generators: [timestamp_type: :utc_datetime]

config :timely, TimelyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TimelyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Timely.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :timely, :mail_from, {"Timely", "noreply@timely.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :timely, :redis, uri: "redis://localhost:6379/0", key_prefix: "timely:"

# Elixir ships a UTC-only time zone database by default, which makes
# DateTime.shift_zone/2 fail for every IANA zone. GET /api/v1/reports/summary
# buckets by day in the caller's zone, so the fallback would silently report the
# wrong day for evening work.
config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :timely, Timely.Guardian,
  issuer: "timely",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :timely, :oidc_enabled, false
config :timely, :saml_enabled, false
config :timely, :google_enabled, false
config :timely, :facebook_enabled, false
config :timely, :github_enabled, false
config :timely, :linkedin_enabled, false
config :timely, :sso_require_invite, false
config :timely, :sso_domains, %{}
config :timely, :sso_auto_approve_domains, []
config :timely, :sso_domain_policies, %{}

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# Background jobs
config :timely, Oban,
  repo: Timely.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", Timely.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :timely, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :timely, TimelyWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
