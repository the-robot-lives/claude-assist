import Config

config :seed_helper,
  repo: TheRobotRemembers.Repo

config :smart_token,
  repo: TheRobotRemembers.Repo

config :the_robot_remembers, TheRobotRemembers.Repo,
  types: TheRobotRemembers.PostgrexTypes,
  migration_primary_key: [name: :id, type: :uuid]

config :the_robot_remembers,
  ecto_repos: [TheRobotRemembers.Repo],
  generators: [timestamp_type: :utc_datetime]

config :the_robot_remembers, TheRobotRemembersWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TheRobotRemembersWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TheRobotRemembers.PubSub

config :noizu_sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY") || "SG.dev-placeholder"

config :the_robot_remembers, :mail_from,
  {"TheRobotRemembers", "noreply@starter.local"}

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :the_robot_remembers, :redis, uri: "redis://localhost:6379/0", key_prefix: "starter:"

config :the_robot_remembers, TheRobotRemembers.Guardian,
  issuer: "the_robot_remembers",
  secret_key: "dev-secret-key-change-in-production"

# SSO feature flags (all disabled by default, enabled via runtime env vars)
config :ueberauth, Ueberauth, providers: []

config :the_robot_remembers, :oidc_enabled, false
config :the_robot_remembers, :saml_enabled, false
config :the_robot_remembers, :google_enabled, false
config :the_robot_remembers, :facebook_enabled, false
config :the_robot_remembers, :github_enabled, false
config :the_robot_remembers, :linkedin_enabled, false
config :the_robot_remembers, :sso_require_invite, false

config :junit_formatter,
  report_file: "results.xml"

# Rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS,
    [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000 * 10]}

# SAML handler
config :samly, Samly.Provider,
  pipeline_handler: TheRobotRemembersWeb.SAMLHandler

# Background jobs
config :the_robot_remembers, Oban,
  repo: TheRobotRemembers.Repo,
  queues: [mailer: 10, default: 10, cleanup: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */6 * * *", TheRobotRemembers.Workers.CleanupWorker}
     ]}
  ]

# Feature flags
config :the_robot_remembers, :feature_flags, %{
  email_verification: true,
  webhooks: false,
  file_uploads: false
}

# i18n
config :the_robot_remembers, TheRobotRemembersWeb.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
